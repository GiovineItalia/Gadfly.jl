
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
        g.color = Color[color("steelblue")]
        new(g)
    end
end

const geom_point = PointGeometry()


function check_xy(aes::Aesthetics)
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
end


function render(geom::PointGeometry, aes::Aesthetics)
    println("render point geom")

    check_xy(aes)

    aes = inherit(aes, geom.default_aes)

    forms = Array(Any, n)
    for ((x, y, s), i) in enumerate(zip(aes.x, aes.y, cycle(aes.size)))
        forms[i] = Circle(x, y, s)
    end

    if length(aes.color) == 1
        form = compose!(forms..., Fill(aes.color[1]))
    else
        for (f, c) in zip(forms, aes.color)
            compose!(f, Fill(c))
        end
        form = compose!(forms...)
    end

    compose!(form, Stroke(nothing))
end


type LineGeometry <: Geometry
    default_aes::Aesthetics

    function LineGeometry()
        g = Aesthetics()
        g.size  = Measure[0.5mm]
        g.color = Color[color("steelblue")]
        new(g)
    end
end

const geom_line = LineGeometry()


function render(geom::LineGeometry, aes::Aesthetics)
    println("render line geom")

    check_xy(aes)

    aes = inherit(aes, geom.default_aes)

    if length(aes.color) == 1
        compose!(Lines({(x, y) for (x, y) in zip(aes.x, aes.y)}...),
                 Stroke(aes.color[1]), Fill(nothing))
    else
        # TODO: How does this work?
        # Which line gets the point? Do we do a gradient
        # between the two?
    end
end


