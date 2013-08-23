
module Coord

using Gadfly
using Compose

import Gadfly.Maybe
export cartesian

# Cartesian coordinates with position given by the x and y (and similar)
# aesthetics.
#
# Args:
#   xvars: Aesthetics to consider when choosing x bounds.
#   yvars: Aesthetics to consider when choosing y bounds.
#   xmin, xmax, ymin, ymax:
#     Force a particular x or y bound, rather than trying to choose it
#     from the data.
#
#
immutable Cartesian <: Gadfly.CoordinateElement
    xvars::Vector{Symbol}
    yvars::Vector{Symbol}
    xmin
    xmax
    ymin
    ymax

    function Cartesian(
            xvars=[:x, :xviewmin, :xviewmax, :xmin, :xmax],
            yvars=[:y, :yviewmin, :yviewmax, :ymin, :ymax, :middle,
                   :lower_hinge, :upper_hinge, :lower_fence, :upper_fence, :outliers];
            xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing)
        new(xvars, yvars, xmin, xmax, ymin, ymax)
    end
end


const cartesian = Cartesian


# Produce a canvas with suitable cartesian coordinates.
#
# Args:
#   coord: cartesian coordinate instance.
#
# Returns:
#   A compose Canvas.
#
function apply_coordinate(coord::Cartesian, aess::Gadfly.Aesthetics...)
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

            # Outliers is an odd aesthetic that needs special treatment.
            if var == :outliers
                for vals in aes.outliers
                    for val in vals
                        if val < ymin
                            ymin = val
                        end

                        if val > ymax
                            ymax = val
                        end
                    end
                end

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

    xmin = coord.xmin === nothing ? xmin : coord.xmin
    xmax = coord.xmax === nothing ? xmax : coord.xmax
    ymin = coord.ymin === nothing ? ymin : coord.ymin
    ymax = coord.ymax === nothing ? ymax : coord.ymax

    if !isfinite(xmin)
        xmin = 0.0
        xmax = 1.0
    end

    if !isfinite(ymin)
        ymin = 0.0
        ymax = 1.0
    end

    # A bit of kludge. We need to extend a bit to be able to fit bars when
    # using discrete scales. TODO: Think more carefully about this. Is there a
    # way for the geometry to let the coordinates know that a little extra room
    # is needed to draw everything?
    if all([aes.x === nothing || typeof(aes.x) == Array{Int64, 1} for aes in aess])
        xmin -= 0.5
        xmax += 0.5
    end
    xpadding = 0.03 * (xmax - xmin)

    if all([aes.y === nothing || typeof(aes.y) == Array{Int64, 1} for aes in aess])
        ymin -= 0.5
        ymax += 0.5
    end
    ypadding = 0.03 * (ymax - ymin)

    width  = xmax - xmin + 2xpadding
    height = ymax - ymin + 2ypadding

    canvas(unit_box=Units(xmin - xpadding, ymax + ypadding, width, -height))
end

end # module Coord

