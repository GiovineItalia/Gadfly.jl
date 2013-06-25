
require("Codecs")
require("Compose")
require("DataFrames")
require("Distributions")
require("Iterators")
require("JSON")

module Gadfly

using Codecs
using Color
using Compose
using DataFrames
using JSON

import Iterators
import Compose.draw, Compose.hstack, Compose.vstack
import Base.copy, Base.push!, Base.start, Base.next, Base.done, Base.has,
       Base.show, Base.getindex

export Plot, Layer, Scale, Coord, Geom, Guide, Stat, render, plot, @plot, spy

# Re-export some essentials from Compose
export SVG, PNG, PS, PDF, draw, inch, mm, px, pt, color

typealias ColorOrNothing Union(ColorValue, Nothing)


element_aesthetics(::Any) = []
default_scales(::Any) = []


abstract Element
abstract ScaleElement       <: Element
abstract CoordinateElement  <: Element
abstract GeometryElement    <: Element
abstract GuideElement       <: Element
abstract StatisticElement   <: Element


include("misc.jl")
include("ticks.jl")
include("color.jl")
include("theme.jl")
include("aesthetics.jl")
include("data.jl")
include("weave.jl")
include("poetry.jl")


# A plot has zero or more layers. Layers have a particular geometry and their
# own data, which is inherited from the plot if not given.
type Layer <: Element
    data::Data
    geom::GeometryElement
    statistic::StatisticElement

    function Layer()
        new(Data(), Geom.nil, Stat.nil)
    end
end


# A full plot specification.
type Plot
    layers::Vector{Layer}
    data::Data
    scales::Vector{ScaleElement}
    statistics::Vector{StatisticElement}
    coord::CoordinateElement
    guides::Vector{GuideElement}
    theme::Theme
    mapping::Dict

    function Plot()
        new(Layer[], Data(), ScaleElement[], StatisticElement[],
            Coord.cartesian, GuideElement[], default_theme)
    end
end


function add_plot_element(p::Plot, data::AbstractDataFrame, arg::GeometryElement)
    layer = Layer()
    layer.geom = arg
    push!(p.layers, layer)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::ScaleElement)
    push!(p.scales, arg)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::StatisticElement)
    if isempty(p.layers)
        push!(p.layers, Layer())
    end

    p.layers[end].statistic = arg
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::CoordinateElement)
    push!(p.coordinates, arg)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::GuideElement)
    push!(p.guides, arg)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::Layer)
    push!(p.layers, arg)
end


eval_plot_mapping(data::AbstractDataFrame, arg::Symbol) = data[string(arg)]
eval_plot_mapping(data::AbstractDataFrame, arg::String) = data[arg]
eval_plot_mapping(data::AbstractDataFrame, arg::Integer) = data[arg]
eval_plot_mapping(data::AbstractDataFrame, arg::Expr) = with(data, arg)

# Acceptable types of values that can be bound to aesthetics.
typealias AestheticValue Union(Nothing, Symbol, String, Integer, Expr)


# Create a new plot.
#
# Grammar of graphics style plotting consists of specifying a dataset, one or
# more plot elements (scales, coordinates, geometries, etc), and binding of
# aesthetics to columns or expressions of the dataset.
#
# For example, a simple scatter plot would look something like:
#
#     plot(my_data, Geom.point, x="time", y="price")
#
# Where "time" and "price" are the names of columns in my_data.
#
# Args:
#   data: Data to be bound to aesthetics.
#   mapping: Aesthetics symbols (e.g. :x, :y, :color) mapped to
#            names of columns in the data frame or other expressions.
#   elements: Geometries, statistics, etc.

function plot(data::AbstractDataFrame, elements::Element...; mapping...)
    p = Plot()
    p.mapping = Dict()
    valid_aesthetics = Set(names(Aesthetics)...)
    for (k, v) in mapping
        if !has(valid_aesthetics, k)
            error("$(k) is not a recognized aesthetic")
        end

        if !(typeof(v) <: AestheticValue)
            error(
            """Aesthetic $(k) is mapped to a value of type $(typeof(v)).
               It must be mapped to a string, symbol, or expression.""")
        end

        setfield(p.data, k, eval_plot_mapping(data, v))
        p.mapping[k] = v
    end

    for element in elements
        add_plot_element(p, data, element)
    end

    p
end


# The old fashioned (pre named arguments) version of plot.
#
# This version takes an explicit mapping dictionary, mapping aesthetics symbols
# to expressions or columns in the data frame.
#
# Args:
#   data: Data to be bound to aesthetics.
#   mapping: Dictionary of aesthetics symbols (e.g. :x, :y, :color) to
#            names of columns in the data frame or other expressions.
#   elements: Geometries, statistics, etc.
#
# Returns:
#   A Plot object.
#
function plot(data::AbstractDataFrame, mapping::Dict, elements::Element...)
    p = Plot()
    for element in elements
        add_plot_element(p, data, element)
    end

    for (var, value) in mapping
        setfield(p.data, var, eval_plot_mapping(data, value))
    end
    p.mapping = mapping

    p
end


# TODO: We need to then build a layer() function that works very much like plot.


# Turn a graph specification into a graphic.
#
# This is where magic happens (sausage is made). Processing all the parts of the
# plot is actually pretty simple. It's made complicated by trying to handle
# defaults. With that aside, plots are made in the following steps.
#
#    I. Apply scales to transform raw data to the form expected by the aesthetic.
#   II. Apply statistics to the scaled data. Statistics are essentially functions
#       that map one or more aesthetics to one or more aesthetics.
#  III. Apply coordinates. Currently all this does is figure out the coordinate
#       system used by the plot panel canvas.
#   IV. Render geometries. This gives us one or more compose forms suitable to be
#       composed with the plot's panel.
#    V. Render guides. Guides are conceptually very similar to geometries but with
#       the ability to be placed outside of the plot panel.
#
#  Finally there is a very important call to layout_guides which puts everything
#  together.
#
# Args:
#   plot: a plot to render.
#
# Returns:
#   A compose Canvas containing the graphic.
#
function render(plot::Plot)
    # Add default statistics for geometries.
    layer_stats = Array(StatisticElement, length(plot.layers))
    for (i, layer) in enumerate(plot.layers)
        layer_stats[i] = is(layer.statistic, Stat.nil) ?
                            Geom.default_statistic(layer.geom) : layer.statistic
    end

    used_aesthetics = Set{Symbol}()
    for layer in plot.layers
        union!(used_aesthetics, element_aesthetics(layer.geom))
    end

    for stat in layer_stats
        union!(used_aesthetics, element_aesthetics(stat))
    end

    defined_unused_aesthetics = setdiff(Set(keys(plot.mapping)...), used_aesthetics)
    if !isempty(defined_unused_aesthetics)
        warn("The following aesthetics are mapped, but not used by any geometry:\n    ",
             join([string(a) for a in defined_unused_aesthetics], ", "))
    end

    scaled_aesthetics = Set{Symbol}()
    for scale in plot.scales
        union!(scaled_aesthetics, element_aesthetics(scale))
    end

    # Only one scale can be applied to an aesthetic (without getting some weird
    # and incorrect results), so we organize scales into a dict.
    scales = Dict{Symbol, ScaleElement}()
    for scale in plot.scales
        for var in element_aesthetics(scale)
            scales[var] = scale
        end
    end

    unscaled_aesthetics = setdiff(used_aesthetics, scaled_aesthetics)

    # Add default scales for statistics.
    for stat in layer_stats
        for scale in default_scales(stat)
            # Use the statistics default scale only when it covers some
            # aesthetic that is not already scaled.
            scale_aes = Set(element_aesthetics(scale)...)
            if !isempty(intersect(scale_aes, unscaled_aesthetics))
                for var in scale_aes
                    scales[var] = scale
                end
                setdiff!(unscaled_aesthetics, scale_aes)
            end
        end
    end

    # Assign scales to mapped aesthetics first.
    for var in unscaled_aesthetics
        if !haskey(plot.mapping, var)
            continue
        end

        t = classify_data(getfield(plot.data, var))
        if haskey(default_aes_scales[t], var)
            scale = default_aes_scales[t][var]
            scale_aes = Set(element_aesthetics(scale)...)
            for var in scale_aes
                scales[var] = scale
            end
        end
    end

    for var in unscaled_aesthetics
        if haskey(plot.mapping, var) || haskey(scales, var)
            continue
        end

        if haskey(default_aes_scales[:discrete], var)
            scale = default_aes_scales[:discrete][var]
            scale_aes = Set(element_aesthetics(scale)...)
            for var in scale_aes
                scales[var] = scale
            end
        end
    end

    # There can be at most one instance of each guide. This is primarily to
    # prevent default guides being applied over user-supplied guides.
    guides = Dict{Type, GuideElement}()
    for guide in plot.guides
        guides[typeof(guide)] = guide
    end
    guides[Guide.PanelBackground] = Guide.background
    guides[Guide.XTicks] = Guide.x_ticks
    guides[Guide.YTicks] = Guide.y_ticks

    statistics = copy(plot.statistics)
    push!(statistics, Stat.x_ticks)
    push!(statistics, Stat.y_ticks)

    function mapped_and_used(vs)
        any([haskey(plot.mapping, v) && contains(used_aesthetics, v) for v in vs])
    end

    function choose_name(vs)
        for v in vs
            if haskey(plot.mapping, v)
                return string(plot.mapping[v])
            end
        end
        ""
    end

    if mapped_and_used(Scale.x_vars) && !haskey(guides, Guide.XLabel)
        guides[Guide.XLabel] =  Guide.XLabel(choose_name(Scale.x_vars))
    end

    if mapped_and_used(Scale.y_vars) && !haskey(guides, Guide.YLabel)
        guides[Guide.YLabel] = Guide.YLabel(choose_name(Scale.y_vars))
    end

    # I. Scales
    aess = Scale.apply_scales(Iterators.distinct(values(scales)), plot.data,
                              [layer.data for layer in plot.layers]...)

    # set default labels
    if has(plot.mapping, :color)
        aess[1].color_key_title = string(plot.mapping[:color])
    end

    # IIa. Layer-wise statistics
    for (layer_stat, aes) in zip(layer_stats, aess)
        Stat.apply_statistics(StatisticElement[layer_stat], scales, aes)
    end

    # IIb. Plot-wise Statistics
    plot_aes = cat(aess...)
    Stat.apply_statistics(statistics, scales, plot_aes)

    # Add some default guides determined by defined aesthetics
    if !all([aes.color === nothing for aes in [plot_aes, aess...]]) &&
       !has(guides, Guide.ColorKey)
        guides[Guide.ColorKey] = Guide.colorkey
    end

    # III. Coordinates
    plot_canvas = Coord.apply_coordinate(plot.coord, plot_aes, aess...)

    # Now that coordinates are set, layer aesthetics inherit plot aesthetics.
    for aes in aess
        inherit!(aes, plot_aes)
    end

    # IV. Geometries
    plot_canvas = compose(plot_canvas,
                          [render(layer.geom, plot.theme, aes)
                           for (layer, aes) in zip(plot.layers, aess)]...)

    # V. Guides
    guide_canvases = {}
    for guide in values(guides)
        append!(guide_canvases, render(guide, plot.theme, aess))
    end

    canvas = Guide.layout_guides(plot_canvas, plot.theme, guide_canvases...)

    # TODO: This is a kludge. Axis labels sometimes extend past the edge of the
    # canvas.
    pad(canvas, 5mm)
end


# A convenience version of Compose.draw that let's you skip the call to render.
draw(backend::Compose.Backend, p::Plot) = draw(backend, render(p))

# Convenience stacking functions
vstack(ps::Plot...) = vstack([render(p) for p in ps]...)
hstack(ps::Plot...) = hstack([render(p) for p in ps]...)


# Displaying plots, for interactive use.
#
# This is a show function that, rather than outputing a totally incomprehensible
# representation of the Plot object, renders it, and emits the graphic. (Which
# usually means, shows it in a browser window.)
#
#function show(io::IO, p::Plot)
    #draw(SVG(6inch, 5inch), p)
#end
# TODO: Find a more elegant way to automatically show plots. This is unexpected
# and gives weave problems.


include("scale.jl")
include("coord.jl")
include("geometry.jl")
include("guide.jl")
include("statistics.jl")


# All aesthetics must have a scale. If none is given, we use a default.
# The default depends on whether the input is discrete or continuous (i.e.,
# PooledDataVector or DataVector, respectively).
const default_aes_scales = {
        :continuous => {:x     => Scale.x_continuous,
                        :x_min => Scale.x_continuous,
                        :x_max => Scale.x_continuous,
                        :y     => Scale.y_continuous,
                        :y_min => Scale.y_continuous,
                        :y_max => Scale.y_continuous,
                        :color => Scale.color_gradient,
                        :label => Scale.label},
        :discrete   => {:x     => Scale.x_discrete,
                        :x_min => Scale.x_discrete,
                        :x_max => Scale.x_discrete,
                        :y     => Scale.y_discrete,
                        :y_min => Scale.y_discrete,
                        :y_max => Scale.y_discrete,
                        :color => Scale.color_hue,
                        :label => Scale.label}}

# Determine whether the input is discrete or continuous.
classify_data{N}(data::DataArray{Float64, N}) = :continuous
classify_data{N}(data::DataArray{Float32, N}) = :continuous
classify_data(data::DataArray) = :discrete
classify_data(data::PooledDataArray) = :discrete

# Very long unfactorized integer data should be treated as continuous
function classify_data{T <: Integer}(data::DataVector{T})
    length(Set{T}(data...)) <= 20 ? :discrete : :continuous
end


end # module Gadfly

