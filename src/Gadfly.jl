
require("Codecs")
require("Compose")
require("DataFrames")
require("Distributions")
require("Iterators")
require("JSON")
require("Loess")

module Gadfly

using Codecs
using Color
using Compose
using DataFrames
using JSON

import Iterators
import Iterators.distinct
import Compose.draw, Compose.hstack, Compose.vstack
import Base.copy, Base.push!, Base.start, Base.next, Base.done, Base.has,
       Base.show, Base.getindex, Base.cat, Base.writemime

export Plot, Layer, Scale, Coord, Geom, Guide, Stat, render, plot, layer, @plot,
       spy, set_default_plot_size, prepare_display


# Re-export some essentials from Compose
export D3, SVG, PNG, PS, PDF, draw, inch, mm, cm, px, pt, color, vstack, hstack

typealias ColorOrNothing Union(ColorValue, Nothing)


element_aesthetics(::Any) = []
default_scales(::Any) = []


abstract Element
abstract ScaleElement       <: Element
abstract CoordinateElement  <: Element
abstract GeometryElement    <: Element
abstract GuideElement       <: Element
abstract StatisticElement   <: Element


# The layer and plot functions can also take functions that are evaluated with
# no arguments and are expected to produce an element.
typealias ElementOrFunction{T <: Element} Union(Element, Type{T}, Function)


include("misc.jl")
include("ticks.jl")
include("color.jl")
include("theme.jl")
include("aesthetics.jl")
include("data.jl")
include("weave.jl")
include("poetry.jl")


# Prepare the display backend (ijuila, in particular) to show plots rendered on
# the d3 backend.

const gadfly_js = readall(joinpath(Pkg.dir("Gadfly"), "src", "gadfly.js"))


function prepare_display(d::Display)
    Compose.prepare_display(d)
    display(d, "text/html", """<script charset="utf-8">$(gadfly_js)</script>""")
end


function prepare_display()
    prepare_display(Base.Multimedia.displays[end])
end


try
    display("text/html", """<script charset="utf-8">$(gadfly_js)</script>""")
catch
end


# Set prefereed canvas size when rendering a plot with an explicit call to
# `draw`.
default_plot_width = 12cm
default_plot_height = 8cm

function set_default_plot_size(width::Compose.MeasureOrNumber,
                               height::Compose.MeasureOrNumber)
    global default_plot_width
    global default_plot_height
    default_plot_width = Compose.x_measure(width)
    default_plot_height = Compose.y_measure(height)
end


# A plot has zero or more layers. Layers have a particular geometry and their
# own data, which is inherited from the plot if not given.
type Layer <: Element
    data_source::Union(AbstractDataFrame, Nothing)
    mapping::Dict
    statistic::StatisticElement
    geom::GeometryElement

    function Layer()
        new(nothing, Dict(), Stat.nil(), Geom.nil())
    end

    function Layer(data::Union(Nothing, AbstractDataFrame), mapping::Dict,
                   statistic::StatisticElement, geom::GeometryElement)
        new(data, mapping, statistic, geom)
    end

    function Layer(data::Union(Nothing, AbstractDataFrame), mapping::Dict,
                   statistic::Union(Function, Type), geom::GeometryElement)
        new(data, mapping, statistic(), geom)
    end

    function Layer(data::Union(Nothing, AbstractDataFrame), mapping::Dict,
                   statistic::StatisticElement, geom::Union(Function, Type))
        new(data, mapping, statistic, geom())
    end

    function Layer(data::Union(Nothing, AbstractDataFrame), mapping::Dict,
                   statistic::Union(Function, Type), geom::Union(Function, Type))
        new(data, mapping, statistic(), geom())
    end
end


function layer(data::Union(AbstractDataFrame, Nothing),
               statistic::Union(Function, Type, StatisticElement)=Stat.nil(),
               geom::Union(Function, Type, GeometryElement)=Geom.nil;
               mapping...)
    Layer(data, clean_mapping(mapping), statistic, geom)
end


function layer(statistic::Union(Function, Type, StatisticElement),
               geom::Union(Function, Type, GeometryElement);
               mapping...)
    layer(nothing, statistic, geom; mapping...)
end


function layer(geom::Union(Function, Type, GeometryElement); mapping...)
    layer(nothing, Stat.nil(), geom; mapping...)
end


# A full plot specification.
type Plot
    layers::Vector{Layer}
    data_source::Union(Nothing, AbstractDataFrame)
    data::Data
    scales::Vector{ScaleElement}
    statistics::Vector{StatisticElement}
    coord::CoordinateElement
    guides::Vector{GuideElement}
    theme::Theme
    mapping::Dict

    function Plot()
        new(Layer[], nothing, Data(), ScaleElement[], StatisticElement[],
            Coord.cartesian(), GuideElement[], default_theme)
    end
end


function add_plot_element(p::Plot, data::AbstractDataFrame, arg::Function)
    add_plot_element(p, data, arg())
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
    p.coord = arg
end


function add_plot_element(p::Plot, data::AbstractDataFrame, arg::GuideElement)
    push!(p.guides, arg)
end


function add_plot_element(p::Plot, data::AbstractDataFrame, arg::Layer)
    push!(p.layers, arg)
end


function add_plot_element{T <: Element}(p::Plot, data::AbstractDataFrame, f::Type{T})
    add_plot_element(p, data, f())
end


# Evaluate a plot mapping, and update the Data structure appropriately.
#
# Args:
#   data: Data object to be updated.
#   data_source: data frame in which context of which the mapping is evaluated.
#   k: key
#   v: value
#
# Modifies:
#   data
#
function set_mapped_data!(data::Data, data_source::AbstractDataFrame, k::Symbol, v)
    setfield(data, k, eval_plot_mapping(data_source, v))

    if typeof(v) <: AbstractArray
        data.titles[k] = string(v)
    elseif typeof(v) <: String
        data.titles[k] = v
    else
        data.titles[k] = string(k)
    end
end


# Handle aesthetics aliases and warn about unrecognized aesthetics.
#
# Returns:
#   A new mapping with aliases evaluated and unrecognized aesthetics removed.
#
function clean_mapping(mapping)
    cleaned = Dict{Symbol, AestheticValue}()
    for (key, val) in mapping
        if haskey(aesthetic_aliases, key)
            key = aesthetic_aliases[key]
        elseif !in(key, Aesthetics.names)
            warn("$(string(key)) is not a recognized aesthetic. Ignoring.")
            continue
        end

        if !(typeof(val) <: AestheticValue)
            error(
            """Aesthetic $(k) is mapped to a value of type $(typeof(v)).
               It must be mapped to a string, symbol, array, or expression.""")
        end

        cleaned[key] = val
    end
    cleaned
end


# Evaluate a mapping.
eval_plot_mapping(data::AbstractDataFrame, arg::Symbol) = data[string(arg)]
eval_plot_mapping(data::AbstractDataFrame, arg::String) = data[arg]
eval_plot_mapping(data::AbstractDataFrame, arg::Integer) = data[arg]
eval_plot_mapping(data::AbstractDataFrame, arg::Expr) = with(data, arg)
eval_plot_mapping(data::AbstractDataFrame, arg::AbstractArray) = arg

# Acceptable types of values that can be bound to aesthetics.
typealias AestheticValue Union(Nothing, Symbol, String, Integer, Expr,
                               AbstractArray)


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
#   data_source: Data to be bound to aesthetics.
#   mapping: Aesthetics symbols (e.g. :x, :y, :color) mapped to
#            names of columns in the data frame or other expressions.
#   elements: Geometries, statistics, etc.

function plot(data_source::AbstractDataFrame, elements::ElementOrFunction...; mapping...)
    p = Plot()
    p.mapping = clean_mapping(mapping)
    p.data_source = data_source
    valid_aesthetics = Set(names(Aesthetics)...)
    for (k, v) in p.mapping
        set_mapped_data!(p.data, data_source, k, v)
    end

    for element in elements
        add_plot_element(p, data_source, element)
    end

    p
end


function plot(elements::ElementOrFunction...; mapping...)
    plot(DataFrame(), elements...; mapping...)
end


# The old fashioned (pre named arguments) version of plot.
#
# This version takes an explicit mapping dictionary, mapping aesthetics symbols
# to expressions or columns in the data frame.
#
# Args:
#   data_source: Data to be bound to aesthetics.
#   mapping: Dictionary of aesthetics symbols (e.g. :x, :y, :color) to
#            names of columns in the data frame or other expressions.
#   elements: Geometries, statistics, etc.
#
# Returns:
#   A Plot object.
#
function plot(data_source::AbstractDataFrame, mapping::Dict, elements::ElementOrFunction...)
    p = Plot()
    for element in elements
        add_plot_element(p, data_source, element)
    end

    for (var, value) in mapping
        set_mapped_data!(p.data, data_source, var, value)
    end
    p.mapping = mapping
    p.data_source = data_source

    p
end


function plot(mapping::Dict, elements::ElementOrFunction...)
    plot(DataFrame, mapping, elements...)
end


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
    if isempty(plot.layers)
        layer = Layer()
        layer.geom = Geom.point()
        push!(plot.layers, layer)
    end

    # Process layers, filling inheriting mappings or data from the Plot where
    # they are missing.
    datas = Array(Data, length(plot.layers))
    for (i, layer) in enumerate(plot.layers)
        if layer.data_source === nothing && isempty(layer.mapping)
            datas[i] = plot.data
        else
            datas[i] = Data()

            if layer.data_source === nothing
                layer.data_source = plot.data_source
            end

            if isempty(layer.mapping)
                layer.mapping = plot.mapping
            end

            for (k, v) in layer.mapping
                setfield(datas[i], k, eval_plot_mapping(layer.data_source, v))
            end
        end
    end

    # Add default statistics for geometries.
    layer_stats = Array(StatisticElement, length(plot.layers))
    for (i, layer) in enumerate(plot.layers)
        layer_stats[i] = typeof(layer.statistic) == Stat.nil ?
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

        if haskey(default_aes_scales[:categorical], var)
            scale = default_aes_scales[:categorical][var]
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

    statistics = copy(plot.statistics)

    # Default guides and statistics
    facet_plot = true
    for layer in plot.layers
        if typeof(layer.geom) != Geom.subplot_grid
            facet_plot = false
            break
        end
    end

    if !facet_plot
        guides[Guide.PanelBackground] = Guide.background()
        guides[Guide.XTicks] = Guide.xticks()
        guides[Guide.YTicks] = Guide.yticks()

        push!(statistics, Stat.xticks)
        push!(statistics, Stat.yticks)
    end

    function mapped_and_used(vs)
        any([haskey(plot.mapping, v) && in(v, used_aesthetics) for v in vs])
    end

    function choose_name(vs)
        for v in vs
            if haskey(plot.data.titles, v)
                return plot.data.titles[v]
            end
        end
        string(vs[1])
    end

    if mapped_and_used(x_axis_label_aesthetics) && !haskey(guides, Guide.XLabel)
        label = choose_name(x_axis_label_aesthetics)
        if facet_plot && haskey(plot.data.titles, :xgroup)
            label = string(label, " <i><b>by</b></i> ", plot.data.titles[:xgroup])
        end
        guides[Guide.XLabel] = Guide.xlabel(label)
    end

    if mapped_and_used(y_axis_label_aesthetics) && !haskey(guides, Guide.YLabel)
        label = choose_name(y_axis_label_aesthetics)
        if facet_plot && haskey(plot.data.titles, :ygroup)
            label = string(label, " <i><b>by</b></i> ", plot.data.titles[:ygroup])
        end
        guides[Guide.YLabel] = Guide.ylabel(label)
    end

    # I. Scales
    layer_aess = Scale.apply_scales(Iterators.distinct(values(scales)), datas...)

    # set default labels
    if haskey(plot.mapping, :color)
        layer_aess[1].color_key_title = string(plot.mapping[:color])
    end

    # IIa. Layer-wise statistics
    for (layer_stat, aes) in zip(layer_stats, layer_aess)
        Stat.apply_statistics(StatisticElement[layer_stat], scales, plot.coord, aes)
    end

    # IIb. Plot-wise Statistics
    plot_aes = cat(layer_aess...)
    Stat.apply_statistics(statistics, scales, plot.coord, plot_aes)

    # Add some default guides determined by defined aesthetics
    if !all([aes.color === nothing for aes in [plot_aes, layer_aess...]]) &&
       !haskey(guides, Guide.ColorKey)
        guides[Guide.ColorKey] = Guide.colorkey()
    end

    canvas = render_prepared(plot, plot_aes, layer_aess, layer_stats, scales,
                             statistics, collect(values(guides)))

    pad_inner(canvas, 5mm)
end


# Render a plot given a precomputed Aesthetics object for each layer.
#
# Additionally, without all the work to choose reasonable defaults performed by
# `render`. This is a separate function from `render` to facilitate rendering
# subplots.
#
# Args:
#   plot: Plot to be rendered.
#   aess: A vector of precomputed Aesthetics objects of the same length
#       as plot.layers.
#   layer_stats: A vector of statistic elements of the same length as
#       plot.layers.
#   scales: Dictionary mapping an aesthetics symbol to the scale applied to it.
#   statistics: Statistic elements applied plot-wise.
#   guides: Guide elements indexed by type. (Only one type of each guide may
#       be in the same plot.)
#   preserve_plot_canvas_size: Don't squish the plot to fit the guides.
#       Guides will be drawn outside the canvas
#
# Returns:
#   A Compose canvas containing the rendered plot.
#
function render_prepared(plot::Plot,
                         plot_aes::Aesthetics,
                         layer_aess::Vector{Aesthetics},
                         layer_stats::Vector{StatisticElement},
                         scales::Dict{Symbol, ScaleElement},
                         statistics::Vector{StatisticElement},
                         guides::Vector{GuideElement};
                         preserve_plot_canvas_size=false)

    # III. Coordinates
    plot_canvas = Coord.apply_coordinate(plot.coord, plot_aes, layer_aess...)

    # Now that coordinates are set, layer aesthetics inherit plot aesthetics.
    for aes in layer_aess
        inherit!(aes, plot_aes)
    end

    # IV. Geometries
    plot_canvas = compose(plot_canvas,
                          [render(layer.geom, plot.theme, aes)
                           for (layer, aes) in zip(plot.layers, layer_aess)]...)

    # V. Guides
    guide_canvases = {}
    for guide in guides
        append!(guide_canvases, render(guide, plot.theme, layer_aess))
    end

    canvas = Guide.layout_guides(plot_canvas, plot.theme, guide_canvases...,
                                 preserve_plot_canvas_size=preserve_plot_canvas_size)
end


# A convenience version of Compose.draw that let's you skip the call to render.
draw(backend::Compose.Backend, p::Plot) = draw(backend, render(p))

# Convenience stacking functions
vstack(ps::Plot...) = vstack([render(p) for p in ps]...)
vstack(ps::Vector{Plot}) = vstack([render(p) for p in ps]...)

hstack(ps::Plot...) = hstack([render(p) for p in ps]...)
hstack(ps::Vector{Plot}) = hstack([render(p) for p in ps]...)


# writemime functions for all supported compose backends.
#
# TODO: These functions should inspect the plot to choose a reasonable default
# size. (This is mainly a compose todo.)

function writemime(io::IO, ::MIME"text/html", p::Plot)
    draw(D3(default_plot_width, default_plot_height), p)
end


# TODO: the serializeable branch has to be merged before this will work.
#function writemime(io::IO, ::MIME"application/json", p::Plot)
    #JSON.print(io, serialize(p, with_data=true))
#end


function writemime(io::IO, ::MIME"text/plain", p::Plot)
    write(io, "Plot(...)")
end


include("scale.jl")
include("coord.jl")
include("geometry.jl")
include("guide.jl")
include("statistics.jl")


# All aesthetics must have a scale. If none is given, we use a default.
# The default depends on whether the input is discrete or continuous (i.e.,
# PooledDataVector or DataVector, respectively).
const default_aes_scales = {
        :numerical => {:x       => Scale.x_continuous,
                        :xmin    => Scale.x_continuous,
                        :xmax    => Scale.x_continuous,
                        :y       => Scale.y_continuous,
                        :ymin    => Scale.y_continuous,
                        :ymax    => Scale.y_continuous,
                        :xgroup  => Scale.xgroup,
                        :ygroup  => Scale.ygroup,
                        :color   => Scale.color_gradient,
                        :label   => Scale.label()},
        :categorical   => {:x       => Scale.x_discrete,
                        :xmin    => Scale.x_discrete,
                        :xmax    => Scale.x_discrete,
                        :y       => Scale.y_discrete,
                        :ymin    => Scale.y_discrete,
                        :ymax    => Scale.y_discrete,
                        :xgroup  => Scale.xgroup,
                        :ygroup  => Scale.ygroup,
                        :color   => Scale.color_hue,
                        :label   => Scale.label()}}

# Determine whether the input is categorical or numerical

function classify_data{N, T <: Integer}(data::AbstractArray{T, N})
    length(Set(data...)) <= 10 ? :categorical : :numerical
end


function classify_data{N, T <: FloatingPoint}(data::AbstractArray{T, N})
    if all(map(is_int_compatable, data)) && length(Set([int(x) for x in data]...)) <= 10
        :categorical
    else
        :numerical
    end
end

classify_data(data::AbstractArray)   = :categorical

# Axis labels are taken whatever is mapped to these aesthetics, in order of
# preference.
const x_axis_label_aesthetics = [:x, :xmin, :xmax]
const y_axis_label_aesthetics = [:y, :ymin, :ymax]

end # module Gadfly

