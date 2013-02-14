
module Coord

using Gadfly
using Compose

export cartesian

# Cartesian coordinates with position given by the x and y (and similar)
# aesthetics.
type CartesianCoordinate <: Gadfly.CoordinateElement
    xvars::Vector{Symbol}
    yvars::Vector{Symbol}
end


const cartesian = CartesianCoordinate(
    [:x, :xtick, :x_min, :x_max],
    [:y, :ytick, :y_min, :y_max, :middle, :lower_hinge, :upper_hinge,
     :lower_fence, :upper_fence, :outliers])


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

    # A bit of kludge. We need to extend a bit to be able to fit bars when
    # using discrete scales. TODO: Think more carefully about this. Is there a
    # way for the geometry to let the coordinates know that a little extra room
    # is needed to draw everything?
    if all([aes.x === nothing || typeof(aes.x) == Array{Int64, 1} for aes in aess])
        xmin -= 0.5
        xmax += 0.5
        xpadding = 0
    else
        xpadding = 0.03 * (xmax - xmin)
    end

    if all([aes.y === nothing || typeof(aes.y) == Array{Int64, 1} for aes in aess])
        ymin -= 0.5
        ymax += 0.5
        ypadding = 0
    else
        ypadding = 0.03 * (ymax - ymin)
    end

    width  = xmax - xmin + 2xpadding
    height = ymax - ymin + 2ypadding

    canvas(Units(xmin - xpadding, ymax + ypadding, width, -height))
end

end # module Coord

