
insert(LOAD_PATH, 1, real_path("../compose/"))
require("compose.jl")

require("scale.jl")
require("transform.jl")
require("coord.jl")
require("data.jl")
require("aesthetics.jl")
require("geometry.jl")
require("theme.jl")
require("guide.jl")
require("statistics.jl")


type Layer
    data::Data
    geom::Geometry
    statistic::Statistic

    function Layer()
        new(Data(), NilGeometry(), IdentityStatistic())
    end
end


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

    # V. Guides
    guide_canvases = Canvas[]
    for guide in plot.guides
        push(guide_canvases, render(guide, plot.theme, aess)...)
    end

    canvas = layout_guides(plot_canvas, guide_canvases...)

    # VI. Geometries
    compose!(plot_canvas, {render(layer.geom, plot.theme, aes)
                           for (layer, aes) in zip(plot.layers, aess)}...)

    canvas
end







# OLD/BUSTED

    ## I. Scales
    #alldata = chain(plot.data, [layer.data for layer in plot.layers]...)
    #fitted_scales = fit_scales(plot.scales, alldata)

    #plot_aes  = apply_scales(fitted_scales, plot.data)

    #layer_aes = [apply_scales(fitted_scales, layer.data)
                 #for layer in plot.layers]
    #layer_aes = [inherit(aes, plot_aes) for aes in layer_aes]

    ## II. Statistics
    #layer_aes = [apply_statistic(layer.stat, aes)
                 #for (layer, aes) in zip(plot.layers, layer_aes)]

    ## III. Coordinates
    #fitted_coord = fit_coord(plot.coord, layer_aes...)
    #plot_canvas = apply_coord(fitted_coord)

    ## IV. Guides
    #guide_canvases = Canvas[]
    #for guide in plot.guides
        #push(guide_canvases,
             #render(guide, plot.theme, layer_aes)...)
    #end

    #canvas = layout_guides(plot_canvas, guide_canvases...)

    ## V. Geometries
    #compose!(plot_canvas, {render(layer, plot.theme, aes)
                           #for (aes, layer) in zip(layer_aes, plot.layers)}...)

    #canvas
#end

