
# Subplot geometries

immutable SubplotLayer
    statistic::Gadfly.StatisticElement
    geom::Gadfly.GeometryElement
end


immutable SubplotGrid <: Gadfly.GeometryElement
    layers::Vector{SubplotLayer}
    statistics::Vector{Gadfly.StatisticElement}
    guides::Vector{Gadfly.GuideElement}

    # Current plot has no way of passing existing aesthetics. It always produces
    # these using scales.
end


const subplot_grid = SubplotGrid


# Render a subplot grid geometry, which consists of rendering and arranging
# many smaller plots.
function render(geom::SubplotGrid, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    if aes.x_group === nothing && aes.y_group === nothing
        error("Geom.subplot_grid requires \"x_group\" and/or \"y_group\" to be bound.")
    end

    aes_grid = aes_by_xy_group(aes)
    n, m = size(aes_grid)

    canvas_grid = Array(Canvas, n, m)
    for i in 1:n, j in 1:m
        p = Plot()
        p.theme = theme
        for layer in geom.layers
            plot_layer = Gadfly.Layer()
            plot_layer.statistic = layer.statistic
            plot_layer.geom = layer.geom
            push!(p.layers, plot_layer)
        end
        aess = fill(aes, length(geom.layers))

        canvas_grid[i, j] =
            render_prepared(p, aess,
                            [layer.statistic for layer in geom.layers],
                            Dict{Symbol, ScalaElement}(),
                            geom.statistics,
                            Dict{Type, GuideElement})
    end

end


