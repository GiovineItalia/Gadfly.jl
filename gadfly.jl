
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
    stat::Statistic

    function Layer()
        new(Data(), NilGeometry(), IdentityStatistic())
    end
end


type Plot
    layers::Vector{Layer}
    data::Data
    scales::Vector{Scale}
    coord::Coordinate
    guides::Guides
    theme::Theme

    function Plot()
        new(Layer[], Data(), Scale[], coord_cartesian, Guide[], default_theme)
    end
end


function render(layer::Layer, theme::Theme, aes::Aesthetics)
    println("render layer")
    render(layer.geom, theme::Theme, aes)
end


function render(plot::Plot)
    # I. Scales
    aess = apply_scales(plot.scales, plot.data,
                        [layer.data for layer in plot.layers]...)

    # II. Transformations
    # No, this should still be part of the scale. But, we need to give
    # statistics access to the scales transformation.
    # Argh. This is the fundamental architecture problem. How to statistics
    # learn about transformations?

    # Currently we use aesthetics to share any information, but transformations
    # are some number of (Symbol, Transform) tuples. That's a little odd to have
    # as an aesthetic. Still, I like having transforms as a seperate thing:
    # scale_x_continuous + transform_x_log10 seems nicer than
    # scale_x_log10. The whole idea of "aesthetics" seems contrived.
    # I'm tempted to dump it and go with UntypedBindings (or "Data") and
    # Bindings. And everything is a binding.


    # III. Statistics
    # 1. Apply the plot's statistics to every layers aes
    # 2. Apply the each layers statistic do its awn aes

    # IV. Coordinates
    # Return a suitable canvas.

    # V. Guides
    # Render shit!

    # VI. Geometries
    # Render more shit!

    nothing
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

