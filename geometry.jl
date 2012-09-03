
require("compose.jl")
require("aesthetics.jl")


abstract Geometry

type NilGeometry <: Geometry
end

function render(geom::NilGeometry, aes::Aesthetics) end


type PointGeometry <: Geometry

end


function render(geom::PointGeometry, aes::Aesthetics)
    println("render point geom")
    if typeof(aes.x) == Nothing || typeof(aes.y) == Nothing
        error("Both `x` and `y` must be defined for point geometry.")
    end

    if length(aes.x) != length(aes.y)
        error("`x` and `y` must be of equal length point geometry.")
    end

    # How do we handle color, shape, etc being optionally defined?
    compose!(Canvas(), {Circle(x, y, 0.5mm) for (x, y) in zip(aes.x, aes.y)}...)
end


