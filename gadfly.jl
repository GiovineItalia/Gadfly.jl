
insert(LOAD_PATH, 1, real_path("../compose/"))
require("compose.jl")

require("scale.jl")
require("coord.jl")
require("data.jl")
require("aesthetics.jl")
require("geometry.jl")
require("theme.jl")
require("guide.jl")


type Layer
    data::Data
    geom::Geometry

    function Layer()
        new(Data(), NilGeometry())
    end
end


typealias Layers Vector{Layer}


type Plot
    layers::Layers
    data::Data
    scales::Scales
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
    alldata = chain(plot.data, [layer.data for layer in plot.layers]...)
    fitted_scales = fit_scales(plot.scales, alldata)

    plot_aes  = apply_scales(fitted_scales, plot.data)

    layer_aes = [apply_scales(fitted_scales, layer.data)
                 for layer in plot.layers]
    layer_aes = [inherit(aes, plot_aes) for aes in layer_aes]

    # II. Statistics
    # TODO

    # III. Coordinates
    fitted_coord = fit_coord(plot.coord, plot_aes, layer_aes...)
    plot_canvas = apply_coord(fitted_coord)

    # IV. Guides
    guide_canvases = Canvas[]
    for guide in plot.guides
        push(guide_canvases,
             render(guide, plot.theme, layer_aes)...)
    end

    canvas = layout_guides(plot_canvas, guide_canvases...)

    # V. Geometries
    compose!(plot_canvas, {render(layer, plot.theme, aes)
                           for (aes, layer) in zip(layer_aes, plot.layers)}...)

    canvas
end

