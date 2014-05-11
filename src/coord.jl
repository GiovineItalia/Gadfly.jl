
module Coord

using Gadfly
using Compose
using DataArrays
import Gadfly.Maybe
import Iterators: cycle

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
    xflip
    yflip

    function Cartesian(
            xvars=[:x, :xviewmin, :xviewmax, :xmin, :xmax],
            yvars=[:y, :yviewmin, :yviewmax, :ymin, :ymax, :middle,
                   :lower_hinge, :upper_hinge, :lower_fence, :upper_fence, :outliers];
            xflip::Bool=false, yflip::Bool=false,
            xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing)
        new(xvars, yvars, xmin, xmax, ymin, ymax, xflip, yflip)
    end
end


const cartesian = Cartesian


# Produce a context with suitable cartesian coordinates.
#
# Args:
#   coord: cartesian coordinate instance.
#
# Returns:
#   A compose Canvas.
#
function apply_coordinate(coord::Cartesian, aess::Gadfly.Aesthetics...)
    xmin = nothing
    xmax = nothing
    for var in coord.xvars
        for aes in aess
            if getfield(aes, var) === nothing
                continue
            end

            vals = getfield(aes, var)
            if !isa(vals, AbstractArray)
                vals = {vals}
            end

            for val in vals
                if !Gadfly.isconcrete(val)
                    continue
                end

                if xmin === nothing || val < xmin
                    xmin = val
                end

                if xmax === nothing || val > xmax
                    xmax = val
                end
            end
        end
    end

    ymin = nothing
    ymax = nothing
    for var in coord.yvars
        for aes in aess
            if getfield(aes, var) === nothing
                continue
            end

            # Outliers is an odd aesthetic that needs special treatment.
            if var == :outliers
                for vals in aes.outliers
                    for val in vals
                        if !Gadfly.isconcrete(val)
                            continue
                        end

                        if ymin === nothing || val < ymin
                            ymin = val
                        end

                        if ymax === nothing || val > ymax
                            ymax = val
                        end
                    end
                end

                continue
            end

            vals = getfield(aes, var)
            if !isa(vals, AbstractArray)
                vals = {vals}
            end

            for val in vals
                if !Gadfly.isconcrete(val)
                    continue
                end

                if ymin === nothing || val < ymin
                    ymin = val
                end

                if ymax === nothing || val > ymax
                    ymax = val
                end
            end
        end
    end

    xmin = coord.xmin === nothing ? xmin : coord.xmin
    xmax = coord.xmax === nothing ? xmax : coord.xmax
    ymin = coord.ymin === nothing ? ymin : coord.ymin
    ymax = coord.ymax === nothing ? ymax : coord.ymax

    if xmin === nothing || !isfinite(xmin)
        xmin = 0.0
        xmax = 1.0
    end


    if ymin === nothing || !isfinite(ymin)
        ymin = 0.0
        ymax = 1.0
    end

    # A bit of kludge. We need to extend a bit to be able to fit bars when
    # using discrete scales. TODO: Think more carefully about this. Is there a
    # way for the geometry to let the coordinates know that a little extra room
    # is needed to draw everything?
    if all([aes.x === nothing || typeof(aes.x) <: PooledDataArray for aes in aess])
        xmin -= 0.5
        xmax += 0.5
        xpadding = 0.0
    else
        xpadding = 0.03 * (xmax - xmin)
    end

    if all([aes.y === nothing || typeof(aes.y) <: PooledDataArray for aes in aess])
        ymin -= 0.5
        ymax += 0.5
        ypadding = 0.0
    else
        ypadding = 0.03 * (ymax - ymin)
    end

    width  = xmax - xmin + 2.0 * xpadding
    height = ymax - ymin + 2.0 * ypadding

    compose!(
        context(units=UnitBox(
            coord.xflip ? xmax + xpadding : xmin - xpadding,
            coord.yflip ? ymin - ypadding : ymax + ypadding,
            coord.xflip ? -width : width,
            coord.yflip ? height : -height)),
        svgclass("plotpanel"))
end

end # module Coord

