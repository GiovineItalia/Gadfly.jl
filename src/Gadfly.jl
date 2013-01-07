

require("Compose")
require("DataFrames")
require("Distributions")
require("Iterators")
require("JSON")

# TODO: It's wrong to put thisg outside the module. What I want to do is have
# Gadfly export everything that's exported by Compose, to avoid having to do
# both using(Gadfly) and using(Compose), but I'm not sure if that's possible.
#using Compose

module Gadfly

using Compose
using DataFrames

import Iterators
import JSON
import Compose.draw
import Base.copy, Base.push, Base.start, Base.next, Base.done

export Plot, Layer, Scale, Coord, Geom, Guide, Stat, render, plot


element_aesthetics(::Any) = []


abstract Element
abstract ScaleElement       <: Element
abstract CoordinateElement  <: Element
abstract GeometryElement    <: Element
abstract GuideElement       <: Element
abstract StatisticElement   <: Element


include("$(julia_pkgdir())/Gadfly/src/misc.jl")
include("$(julia_pkgdir())/Gadfly/src/color.jl")
include("$(julia_pkgdir())/Gadfly/src/theme.jl")
include("$(julia_pkgdir())/Gadfly/src/aesthetics.jl")
include("$(julia_pkgdir())/Gadfly/src/data.jl")
include("$(julia_pkgdir())/Gadfly/src/weave.jl")


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
    insert(p.layers, 1, layer)
    # XXX: I weirdly get a stack overflow error from this, which is probably a
    # julia bug.
    #push(p.layers, layer)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::ScaleElement)
    push(p.scales, arg)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::StatisticElement)
    if isempty(p.layers)
        push(p.layers, Layer())
    end

    p.layers[end].statistics = arg
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::CoordinateElement)
    push(p.coordinates, arg)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::GuideElement)
    push(p.guides, arg)
end

function add_plot_element(p::Plot, data::AbstractDataFrame, arg::Layer)
    push(p.layers, arg)
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
    # 0. Insert default scales
    used_aesthetics = Set{Symbol}()
    for layer in plot.layers
        add_each(used_aesthetics, element_aesthetics(layer.geom))
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

    scales = copy(plot.scales)
    for var in used_aesthetics - scaled_aesthetics
        t = has(plot.mapping, var) ?
                classify_data(getfield(plot.data, var)) : :discrete
        if has(default_scales[t], var)
            push(scales, default_scales[t][var])
        end
    end

    layer_stats = Array(StatisticElement, length(plot.layers))
    for (i, layer) in enumerate(plot.layers)
        layer_stats[i] = is(layer.statistic, Stat.nil) ?
                            Geom.default_statistic(layer.geom) : layer.statistic
    end

    # TODO: Reasonable handling of default guides. Currently x/y ticks are
    # always on and there is no way to turn them off. Think of a good way to
    # supress defaults.
    guides = copy(plot.guides)
    push(guides, Guide.background)
    push(guides, Guide.x_ticks)
    push(guides, Guide.y_ticks)

    if has(plot.mapping, :color) && has(used_aesthetics, :color)
        push(guides, Guide.ColorKey(string(plot.mapping[:color])))
    end

    statistics = copy(plot.statistics)
    push(statistics, Stat.x_ticks)
    push(statistics, Stat.y_ticks)

    if has(plot.mapping, :x) && has(used_aesthetics, :x)
        push(guides, Guide.XLabel(string(plot.mapping[:x])))
    end

    if has(plot.mapping, :y) && has(used_aesthetics, :y)
        push(guides, Guide.YLabel(string(plot.mapping[:y])))
    end

    # I. Scales
    aess = Scale.apply_scales(scales, plot.data,
                              [layer.data for layer in plot.layers]...)

    # IIa. Layer-wise statistics
    for (layer_stat, aes) in zip(layer_stats, aess)
        Stat.apply_statistics(StatisticElement[layer_stat], aes)
    end

    # IIb. Plot-wise Statistics
    plot_aes = cat(aess...)
    Stat.apply_statistics(statistics, plot_aes)

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
    names!(df, ["x", "f(x)"])
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
        df_i = evalfunc(f, a, b, 100)
        name = typeof(f) == Expr ? string(f) : @sprintf("f<sub>%d</sub>", i)
        df_i = cbind(df_i, [name for _ in 1:size(df_i)[1]])
        names!(df_i, ["x", "f(x)", "f"])
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


include("$(julia_pkgdir())/Gadfly/src/scale.jl")
include("$(julia_pkgdir())/Gadfly/src/coord.jl")
include("$(julia_pkgdir())/Gadfly/src/geometry.jl")
include("$(julia_pkgdir())/Gadfly/src/guide.jl")
include("$(julia_pkgdir())/Gadfly/src/statistics.jl")

import Scale, Coord, Geom, Guide, Stat

# All aesthetics must have a scale. If none is given, we use a default.
# The default depends on whether the input is discrete or continuous (i.e.,
# PooledDataVector or DataVector, respectively).
const default_scales = {
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

