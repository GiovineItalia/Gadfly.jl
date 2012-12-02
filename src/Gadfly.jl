
module Gadfly

load("Compose.jl")
import Compose

load("Gadfly/src/scale.jl")
load("Gadfly/src/transform.jl")
load("Gadfly/src/coord.jl")
load("Gadfly/src/data.jl")
load("Gadfly/src/aesthetics.jl")
load("Gadfly/src/geometry.jl")
load("Gadfly/src/theme.jl")
load("Gadfly/src/guide.jl")
load("Gadfly/src/statistics.jl")


# A plot has zero or more layers. Layers have a particular geometry and their
# own data, which is inherited from the plot if not given.
type Layer
    data::Data
    geom::Geometry
    statistic::Statistic

    function Layer()
        new(Data(), NilGeometry(), IdentityStatistic())
    end
end


# A full plot specification.
type Plot
    layers::Vector{Layer}
    data::Data
    scales::Vector{Scale}
    transforms::Vector{Transform}
    statistics::Vector{Statistic}
    coord::Coordinate
    guides::Guides
    theme::Theme

    function Plot()
        new(Layer[], Data(), Scale[], Transform[], Statistic[],
            coord_cartesian, Guide[], default_theme)
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
    aess = apply_scales(plot.scales, plot.data,
                        [layer.data for layer in plot.layers]...)

    # II. Transformations
    apply_transforms(plot.transforms, aess)

    # Organize transforms
    trans_map = Dict{Symbol, Transform}()
    for transform in plot.transforms
        trans_map[transform.var] = transform
    end

    # IIIa. Layer-wise statistics
    for (layer, aes) in zip(plot.layers, aess)
        apply_statistics(Statistic[layer.statistic], aes, trans_map)
    end

    # IIIb. Plot-wise Statistics
    plot_aes = cat(aess...)
    apply_statistics(plot.statistics, plot_aes, trans_map)

    # IV. Coordinates
    plot_canvas = apply_coordinate(plot.coord, plot_aes, aess...)

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

    canvas = layout_guides(plot_canvas, guide_canvases...)

    canvas
end

end # module Gadfly
