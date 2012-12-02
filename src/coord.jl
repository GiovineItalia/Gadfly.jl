
module Coord

export cartesian

import Gadfly

load("Compose.jl")
using Compose

# Cartesian coordinates with position given by the x and y (and similar)
# aesthetics.
type CartesianCoordinate <: Gadfly.CoordinateElement
    xvars::Vector{Symbol}
    yvars::Vector{Symbol}
end


const cartesian = CartesianCoordinate([:x, :xtick], [:y, :ytick])


# Produce a canvas with suitable cartesian coordinates.
#
# Args:
#   coord: cartesian coordinate instance.
#
# Returns:
#   A compose Canvas.
#
function apply_coordinate(coord::CartesianCoordinate, aess::Gadfly.Aesthetics...)
    xmin = Inf
    xmax = -Inf
    for var in coord.xvars
        for aes in aess
            if getfield(aes, var) === nothing
                continue
            end

            for val in getfield(aes, var)
                if val < xmin
                    xmin = val
                end

                if val > xmax
                    xmax = val
                end
            end
        end
    end

    ymin = Inf
    ymax = -Inf
    for var in coord.yvars
        for aes in aess
            if getfield(aes, var) === nothing
                continue
            end

            for val in getfield(aes, var)
                if val < ymin
                    ymin = val
                end

                if val > ymax
                    ymax = val
                end
            end
        end
    end

    xpadding = 0.03 * (xmax - xmin)
    ypadding = 0.03 * (ymax - ymin)

    width  = xmax - xmin + 2xpadding
    height = ymax - ymin + 2ypadding

    canvas(Units(xmin - xpadding, ymax + ypadding, width, -height))
end

end # module Coord

