
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


function render(layer::Layer, aes::Aesthetics)
    println("render layer")
    render(layer.geom, aes)
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
    canvas = apply_coord(fitted_coord)

    # IV. Guides
    compose!(canvas, [render(guide, plot.theme, layer_aes)
                      for guide in plot.guides])

    # V. Geometries
    compose!(canvas, {render(layer, aes)
                        for (aes, layer) in zip(layer_aes, plot.layers)}...)
end





