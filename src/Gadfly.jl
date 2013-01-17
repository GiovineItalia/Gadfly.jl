

require("Compose")
require("DataFrames")
require("Distributions")
require("Iterators")
require("JSON")

# TODO: It's wrong to put this outside the module. What I want to do is have
# Gadfly export everything that's exported by Compose, to avoid having to do
# both using(Gadfly) and using(Compose), but I'm not sure if that's possible.
#using Compose

module Gadfly

using Compose
using DataFrames

import Iterators
import JSON
import Compose.draw, Compose.hstack, Compose.vstack
import Base.copy, Base.push!, Base.start, Base.next, Base.done, Base.has

export Plot, Layer, Scale, Coord, Geom, Guide, Stat, render, plot


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
    insert!(p.layers, 1, layer)
    # XXX: I weirdly get a stack overflow error from this, which is probably a
    # julia bug.
    #push!(p.layers, layer)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::ScaleElement)
    push!(p.scales, arg)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::StatisticElement)
    if isempty(p.layers)
        push!(p.layers, Layer())
    end

    p.layers[end].statistics = arg
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


# This is the primary function used to produce plots, which are then turned into
# compose objects with `render` and drawn to an image with `draw`.
#
# The first argument is always a data frame that will be plotted. There are then
# any number of arguments each of which is either a plot element (geometry,
# statistic, etc) or a mapping which maps a plot aesthetic to a column in the
# data frame..
#
# As an example, you might write something like:
#
#     plot(my_data, (:x, :height), Geom.histogram)
#
# To plot a histogram of some height measurements.
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
        add_each(used_aesthetics, element_aesthetics(layer.geom))
    end

    for stat in layer_stats
        add_each(used_aesthetics, element_aesthetics(stat))
    end

    defined_unused_aesthetics = Set(keys(plot.mapping)...) - used_aesthetics
    if !isempty(defined_unused_aesthetics)
        println("Warning: the following aesthetics are mapped, but not used by any geometry:\n    ",
                join([string(a) for a in defined_unused_aesthetics], ", "))
    end

    scaled_aesthetics = Set{Symbol}()
    for scale in plot.scales
        add_each(scaled_aesthetics, element_aesthetics(scale))
    end

    # Only one scale can be applied to an aesthetic (without getting some weird
    # and incorrect results), so we organize scales into a dict.
    scales = Dict{Symbol, ScaleElement}()
    for scale in plot.scales
        for var in element_aesthetics(scale)
            scales[var] = scale
        end
    end

    unscaled_aesthetics = used_aesthetics - scaled_aesthetics

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
                unscaled_aesthetics -= scale_aes
            end
        end
    end

    # Add default scales for mapped aesthetics.
    while !isempty(unscaled_aesthetics)
        var = pop!(unscaled_aesthetics)
        t = has(plot.mapping, var) ?
                classify_data(getfield(plot.data, var)) : :discrete
        if has(default_aes_scales[t], var)
            scale = default_aes_scales[t][var]
            scale_aes = Set(element_aesthetics(scale)...)
            for var in scale_aes
                scales[var] = scale
            end
            unscaled_aesthetics -= scale_aes
        end
    end

    # TODO: Reasonable handling of default guides. Currently x/y ticks are
    # always on and there is no way to turn them off. Think of a good way to
    # supress defaults.
    guides = copy(plot.guides)
    push!(guides, Guide.background)
    push!(guides, Guide.x_ticks)
    push!(guides, Guide.y_ticks)

    statistics = copy(plot.statistics)
    push!(statistics, Stat.x_ticks)
    push!(statistics, Stat.y_ticks)

    if has(plot.mapping, :x) && has(used_aesthetics, :x)
        push!(guides, Guide.XLabel(string(plot.mapping[:x])))
    end

    if has(plot.mapping, :y) && has(used_aesthetics, :y)
        push!(guides, Guide.YLabel(string(plot.mapping[:y])))
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
    if !all([aes.color === nothing for aes in [plot_aes, aess...]])
        push!(guides, Guide.colorkey)
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
    for guide in guides
        append!(guide_canvases, render(guide, plot.theme, aess))
    end

    canvas = Guide.layout_guides(plot_canvas, guide_canvases...)

    # TODO: This is a kludge. Axis labels sometimes extend past the edge of the
    # canvas.
    pad(canvas, 5mm)
end


## Return a DataFrame with x, y column suitable for plotting a function.
#
# Args:
#  f: Function/Expression to be evaluated.
#  a: Lower bound.
#  b: Upper bound.
#  n: Number of points to evaluate the function at.
#
# Returns:
#
#
function evalfunc(f::Function, a, b, n)
    xs = [x for x in a:(b - a)/n:b]
    df = DataFrame(xs, map(f, xs))
    colnames!(df, ["x", "f(x)"])
    df
end


evalfunc(f::Expr, a, b, n) = evalfunc(eval(:(x -> $f)), a, b, n)


# A convenience plot function for quickly plotting functions are expressions.
#
# Args:
#
# Returns:
#
function plot(fs::Array, a, b, elements::Element...)
    df = DataFrame()
    for (i, f) in enumerate(fs)
        df_i = evalfunc(f, a, b, 250)
        name = typeof(f) == Expr ? string(f) : @sprintf("f<sub>%d</sub>", i)
        df_i = cbind(df_i, [name for _ in 1:size(df_i)[1]])
        colnames!(df_i, ["x", "f(x)", "f"])
        df = rbind(df, df_i)
    end

    mapping = {:x => "x", :y => "f(x)"}
    if length(fs) > 1
        mapping[:color] = "f"
    end

    plot(df, mapping, Geom.line, elements...)
end


function plot(f::Function, a, b, elements::Element...)
    plot([f], a, b, elements...)
end


function plot(f::Expr, a, b, elements::Element...)
    plot([f], a, b, elements...)
end


# A convenience version of Compose.draw that let's you skip the call to render.
draw(backend::Compose.Backend, p::Plot) = draw(backend, render(p))

# Convenience stacking functions
vstack(ps::Plot...) = vstack([render(p) for p in ps]...)
hstack(ps::Plot...) = hstack([render(p) for p in ps]...)


include("scale.jl")
include("coord.jl")
include("geometry.jl")
include("guide.jl")
include("statistics.jl")

import Scale, Coord, Geom, Guide, Stat

# All aesthetics must have a scale. If none is given, we use a default.
# The default depends on whether the input is discrete or continuous (i.e.,
# PooledDataVector or DataVector, respectively).
const default_aes_scales = {
        :continuous => {:x     => Scale.x_continuous,
                        :y     => Scale.y_continuous,
                        :color => Scale.color_hue,
                        :label => Scale.label},
        :discrete   => {:x     => Scale.x_discrete,
                        :y     => Scale.y_discrete,
                        :color => Scale.color_hue,
                        :label => Scale.label}}

# Determine whether the input is discrete or continuous.
classify_data(data::DataVector{Float64}) = :continuous
classify_data(data::DataVector{Float32}) = :continuous
classify_data(data::DataVector) = :discrete
classify_data(data::PooledDataVector) = :discrete


end # module Gadfly

