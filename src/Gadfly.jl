
load("Compose.jl")
import Compose

module Gadfly

import Base.copy

export Plot, Layer, Scale, Trans, Coord, Geom, Guide, Stat, render

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
type Layer
    data::Data
    geom::GeometryElement
    statistic::StatisticElement

    function Layer()
        new(Data(), Geom.nil, Stat.identity)
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

    function Plot()
        new(Layer[], Data(), ScaleElement[], TransformElement[],
            StatisticElement[], Coord.cartesian, GuideElement[], default_theme)
    end
end


# Turn a graph specification into a graphic.
#
# Args:
#   plot: a plot to render.
#
# Returns:
#   A compose Canvas containing the graphic.
#
function render(plot::Plot)
    # I. Scales
    aess = Scale.apply_scales(plot.scales, plot.data,
                              [layer.data for layer in plot.layers]...)

    # II. Transformations
    Trans.apply_transforms(plot.transforms, aess)

    # Organize transforms
    trans_map = Dict{Symbol, TransformElement}()
    for transform in plot.transforms
        trans_map[transform.var] = transform
    end

    # IIIa. Layer-wise statistics
    for (layer, aes) in zip(plot.layers, aess)
        Stat.apply_statistics(StatisticElement[layer.statistic], aes, trans_map)
    end

    # IIIb. Plot-wise Statistics
    plot_aes = cat(aess...)
    Stat.apply_statistics(plot.statistics, plot_aes, trans_map)

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
    for guide in plot.guides
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
