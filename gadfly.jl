
insert(LOAD_PATH, 1, real_path("../compose/"))
require("compose.jl")

require("scale.jl")
require("coord.jl")
require("data.jl")
require("aesthetics.jl")
require("geometry.jl")
require("theme.jl")


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
    coords::Coordinates
    #guides::Guides
    theme::Theme

    function Plot()
        new(Layer[], Data(), Scale[], Coordinates[], default_theme)
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
    fitted_coords = fit_coords(plot.coords, plot_aes, layer_aes...)
    #layer_aes = [apply[


    # TODO: apply coordinates here
    #aes = scaled_data

    # IV. Guides
    #panel = Canvas()
    #if !is(plot.theme.panel_background, nothing)
        #compose!(panel, {Rectangle(), Fill(plot.theme.panel_background),
                                      #Stroke(nothing)})
    #end

    #for guide in plot.guides

    #end

    # V. Geometries
    #compose!(panel, {render(layer, plot, aes) for layer in plot.layers}...)
end





