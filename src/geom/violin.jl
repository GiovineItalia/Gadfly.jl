
immutable ViolinGeometry <: Gadfly.GeometryElement
    order::Int
    tag::Symbol

    function ViolinGeometry(; order=1, tag::Symbol=empty_tag)
        new(order, tag)
    end
end


const violin = ViolinGeometry

element_aesthetics(::ViolinGeometry) = [:x, :y, :color]

default_statistic(::ViolinGeometry) = Gadfly.Stat.violin()


function render(geom::ViolinGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    # TODO: What should we do with the color aesthetic?

    Gadfly.assert_aesthetics_defined("Geom.violin", aes, :y, :width)
    Gadfly.assert_aesthetics_equal_length("Geom.violin", aes, :y, :width)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGB{Float32}[theme.default_color])
    default_aes.x = Float64[0.5]
    aes = inherit(aes, default_aes)

    n = length(aes.y)

    # Group y and width by x
    grouped_y     = DefaultDict(eltype(aes.x), typeof(aes.y), () -> similar(aes.y, 0))
    grouped_width = DefaultDict(eltype(aes.x), typeof(aes.width), () -> similar(aes.width, 0))
    for (x, y, w) in zip(cycle(aes.x), aes.y, aes.width)
        push!(grouped_y[x], y)
        push!(grouped_width[x], w)
    end

    ctx = context(order=geom.order)
    compose!(ctx,
             Compose.polygon([vcat([(x - w/2, y) for (y, w) in zip(grouped_y[x], grouped_width[x])],
                                   reverse!([(x + w/2, y) for (y, w) in zip(grouped_y[x], grouped_width[x])]))
                              for x in keys(grouped_y)], geom.tag))


    return compose!(ctx,
                    fill(theme.default_color),
                    svgclass("geometry"))
end
