
require("compose.jl")
require("aesthetics.jl")
require("theme.jl")


abstract Geometry

type NilGeometry <: Geometry
end

function render(geom::NilGeometry, aes::Aesthetics) end

type PointGeometry <: Geometry
    default_aes::Aesthetics

    function PointGeometry()
        g = Aesthetics()
        g.size  = Measure[0.5mm]
        g.color = Color[color("indianred")]
        new(g)
    end
end


function render(geom::PointGeometry, aes::Aesthetics)
    println("render point geom")

    if typeof(aes.x) == Nothing || typeof(aes.y) == Nothing
        error("Both `x` and `y` must be defined for point geometry.")
    end

    if length(aes.x) != length(aes.y)
        error("`x` and `y` must be of equal length point geometry.")
    end

    n = length(aes.x)

    if !is(aes.color, nothing) && length(aes.color) != n
        error("`color` must be the same length as `x` and `y`.")
    end

    if !is(aes.size, nothing) && length(ael.size) != n
        error("`size` must be the same length as `x` and `y`.")
    end

    aes = inherit(aes, geom.default_aes)

    forms = Array(Any, n)
    for ((x, y, s), i) in enumerate(zip(aes.x, aes.y, cycle(aes.size)))
        forms[i] = Circle(x, y, s)
    end

    if length(aes.color) == 1
        forms = compose!(Canvas(), Fill(aes.color[1]), forms...)
    else
        for (f, c) in zip(forms, aes.color)
            compose!(f, Fill(c))
        end
    end

    compose!(Canvas(), Stroke(nothing), forms)
end


