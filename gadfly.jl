
insert(LOAD_PATH, 1, real_path("../compose/"))
require("compose.jl")

require("scale.jl")
require("coord.jl")
require("data.jl")
require("aesthetics.jl")
require("geometry.jl")


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

    function Plot()
        new(Layer[], Data(), Scale[])
    end
end


function render(layer::Layer, parent::Plot, aes::Aesthetics)
    println("render layer")
    scaled_data = apply_scales(parent.scales, layer.data)
    layer_aes = scaled_data # TODO: coordinates
    aes = inherit(layer_aes, aes)
    render(layer.geom, aes)
end


function render(plot::Plot)
    # WRONG! We need to train on the layer's data also!
    train_scales(plot.scales, plot.data)
    for layer in plot.layers
        train_scales(plot.scales, layer.data)
    end

    scaled_data = apply_scales(plot.scales, plot.data)

    # TODO: apply coordinates here
    aes = scaled_data

    # TODO: Draw background, etc.
    compose!(Canvas(), {render(layer, plot, aes) for layer in plot.layers}...)
end


