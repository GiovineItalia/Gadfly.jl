
load("Compose.jl")
import Compose

module Gadfly

load("DataFrames.jl")
using DataFrames

import Base.copy, Base.push

export Plot, Layer, Scale, Trans, Coord, Geom, Guide, Stat, render, plot

element_aesthetics(::Any) = error("Ahh!")

abstract Element
abstract ScaleElement       <: Element
abstract TransformElement   <: Element
abstract CoordinateElement  <: Element
abstract GeometryElement    <: Element
abstract GuideElement       <: Element
abstract StatisticElement   <: Element

load("Gadfly/src/misc.jl")
load("Gadfly/src/theme.jl")
load("Gadfly/src/aesthetics.jl")
load("Gadfly/src/data.jl")



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
    transforms::Vector{TransformElement}
    statistics::Vector{StatisticElement}
    coord::CoordinateElement
    guides::Vector{GuideElement}
    theme::Theme
    mapping::Dict

    function Plot()
        new(Layer[], Data(), ScaleElement[], TransformElement[],
            StatisticElement[], Coord.cartesian, GuideElement[], default_theme)
    end
end


function add_plot_element(p::Plot, data::DataFrame, arg::GeometryElement)
    layer = Layer()
    layer.geom = arg
    insert(p.layers, 1, layer)
    # XXX: I weirdly get a stack overflow error from this, which is probably a
    # julia bug.
    #push(p.layers, layer)
end

function add_plot_element(p::Plot, data::DataFrame, arg::ScaleElement)
    push(p.scales, arg)
end

function add_plot_element(p::Plot, data::DataFrame, arg::TransformElement)
    push(p.transforms, arg)
end

function add_plot_element(p::Plot, data::DataFrame, arg::StatisticElement)
    # XXX: We should consider making the statistic apply to the last geometry.
    push(p.statistics, arg)
end

function add_plot_element(p::Plot, data::DataFrame, arg::CoordinateElement)
    push(p.coordinates, arg)
end

function add_plot_element(p::Plot, data::DataFrame, arg::GuideElement)
    push(p.guides, arg)
end

function add_plot_element(p::Plot, data::DataFrame, arg::Layer)
    push(p.layers, arg)
end


eval_plot_mapping(data::DataFrame, arg::Symbol) = data[string(arg)]
eval_plot_mapping(data::DataFrame, arg::String) = data[arg]
eval_plot_mapping(data::DataFrame, arg::Expr) = with(data, arg)

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
function plot(data::DataFrame, mapping::Dict, elements::Element...)
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
# Args:
#   plot: a plot to render.
#
# Returns:
#   A compose Canvas containing the graphic.
#
function render(plot::Plot)
    # 0. Insert default scales and transforms
    used_aesthetics = Set{Symbol}()
    for layer in plot.layers
        add_each(used_aesthetics, element_aesthetics(layer.geom))
    end

    scaled_aesthetics = Set{Symbol}()
    for scale in plot.scales
        add_each(scaled_aesthetics, element_aesthetics(scale))
    end

    transformed_aestetics = Set{Symbol}()
    for transform in plot.transforms
        add_each(transformed_aestetics, element_aesthetics(transform))
    end

    scales = copy(plot.scales)
    for var in used_aesthetics - scaled_aesthetics
        push(scales, Scale.ContinuousScale([var]))
    end

    transforms = copy(plot.transforms)
    for var in used_aesthetics - transformed_aestetics
        push(transforms, Trans.IdentityTransform(var))
    end

    layer_stats = Array(StatisticElement, length(plot.layers))
    for (i, layer) in enumerate(plot.layers)
        layer_stats[i] = is(layer.statistic, Stat.nil) ?
                            Geom.default_statistic(layer.geom) : layer.statistic
    end

    # TODO: Reasonable handling of default guides.
    guides = copy(plot.guides)
    push(guides, Guide.background)
    push(guides, Guide.x_ticks)
    push(guides, Guide.y_ticks)
    statistics = copy(plot.statistics)
    push(statistics, Stat.x_ticks)
    push(statistics, Stat.y_ticks)

    if has(plot.mapping, :x)
        push(guides, Guide.XLabel(string(plot.mapping[:x])))
    end

    if has(plot.mapping, :y)
        push(guides, Guide.YLabel(string(plot.mapping[:y])))
    end

    # I. Scales
    aess = Scale.apply_scales(scales, plot.data,
                              [layer.data for layer in plot.layers]...)

    # II. Transformations
    Trans.apply_transforms(transforms, aess)

    # Organize transforms
    trans_map = Dict{Symbol, TransformElement}()
    for transform in plot.transforms
        trans_map[transform.var] = transform
    end

    # IIIa. Layer-wise statistics
    for (layer_stat, aes) in zip(layer_stats, aess)
        Stat.apply_statistics(StatisticElement[layer_stat], aes, trans_map)
    end

    # IIIb. Plot-wise Statistics
    plot_aes = cat(aess...)
    Stat.apply_statistics(statistics, plot_aes, trans_map)

    # IV. Coordinates
    plot_canvas = Coord.apply_coordinate(plot.coord, plot_aes, aess...)

    # Now that coordinates are set, layer aesthetics inherit plot aesthetics.
    for aes in aess
        inherit!(aes, plot_aes)
    end

    # VI. Geometries
    plot_canvas <<= compose({render(layer.geom, plot.theme, aes)
                               for (layer, aes) in zip(plot.layers, aess)}...)

    # VI. Guides
    guide_canvases = {}
    for guide in guides
        append!(guide_canvases, render(guide, plot.theme, aess))
    end

    canvas = Guide.layout_guides(plot_canvas, guide_canvases...)

    canvas
end


load("Gadfly/src/scale.jl")
load("Gadfly/src/transform.jl")
load("Gadfly/src/coord.jl")
load("Gadfly/src/geometry.jl")
load("Gadfly/src/guide.jl")
load("Gadfly/src/statistics.jl")

import Scale, Trans, Coord, Geom, Guide, Stat


end # module Gadfly
