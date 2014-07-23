
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
    xflip::Bool
    yflip::Bool
    fixed::Bool
    aspect_ratio::Union(Nothing, Float64)

    function Cartesian(
            xvars=[:x, :xviewmin, :xviewmax, :xmin, :xmax],
            yvars=[:y, :yviewmin, :yviewmax, :ymin, :ymax, :middle,
                   :lower_hinge, :upper_hinge, :lower_fence, :upper_fence, :outliers];
            xflip::Bool=false, yflip::Bool=false,
            xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing,
            fixed=false, aspect_ratio=nothing)
        new(xvars, yvars, xmin, xmax, ymin, ymax, xflip, yflip, fixed,
            aspect_ratio)
    end
end


const cartesian = Cartesian


# Return the first concrete aesthetic value in one of the given aesthetics
#
# Args:
#   aess: An array of Aesthetics to search through.
#   vars: Aesthetic variables to search though.
#
# Returns:
#   A concrete value if one is found, otherwise nothing.
#
function first_concrete_aesthetic_value(aess::Vector{Gadfly.Aesthetics},
                                        vars::Vector{Symbol})
    T = aesthetics_type(aess, vars)
    for var in vars
        for aes in aess
            vals = getfield(aes, var)
            if vals === nothing
                continue
            end

            if !isa(vals, AbstractArray)
                vals = [vals]
            end

            if var == :outliers
                for outlier_vals in aes.outliers
                    for val in outlier_vals
                        if Gadfly.isconcrete(val)
                            return convert(T, val)
                        end
                    end
                end
                continue
            end

            for val in vals
                if Gadfly.isconcrete(val)
                    return convert(T, val)
                end
            end
        end
    end

    return nothing
end


# Find a common type among a group of aesthetics.
#
# Args:
#   aess: An array of Aesthetics to search through.
#   vars: Aesthetic variables to search though.
#
# Returns:
#   A common type.
function aesthetics_type(aess::Vector{Gadfly.Aesthetics},
                              vars::Vector{Symbol})
    T = None
    for var in vars
        for aes in aess
            vals = getfield(aes, var)
            if vals === nothing
                continue
            end

            if var == :outliers
                if !isempty(vals)
                    T = promote_type(T, eltype(first(vals)))
                end
            else
                T = promote_type(T, eltype(vals))
            end
        end
    end

    return T
end


# Produce a context with suitable cartesian coordinates.
#
# Args:
#   coord: cartesian coordinate instance.
#
# Returns:
#   A compose Canvas.
#
function apply_coordinate(coord::Cartesian, aess::Vector{Gadfly.Aesthetics},
                          scales::Dict{Symbol, Gadfly.ScaleElement})
    xmin = xmax = first_concrete_aesthetic_value(aess, coord.xvars)
    if xmin != nothing
        for var in coord.xvars
            for aes in aess
                vals = getfield(aes, var)
                if vals === nothing
                    continue
                end

                if !isa(vals, AbstractArray)
                    vals = [vals]
                end

                xmin, xmax = Gadfly.concrete_minmax(vals, xmin, xmax)
            end
        end
    end

    ymin = ymax = first_concrete_aesthetic_value(aess, coord.yvars)
    if ymin != nothing
        for var in coord.yvars
            for aes in aess
                vals = getfield(aes, var)
                if vals === nothing
                    continue
                end

                # Outliers is an odd aesthetic that needs special treatment.
                if var == :outliers
                    for outlier_vals in aes.outliers
                        ymin, ymax = Gadfly.concrete_minmax(outlier_vals, ymin, ymax)
                    end

                    continue
                end

                if !isa(vals, AbstractArray)
                    vals = [vals]
                end

                ymin, ymax = Gadfly.concrete_minmax(vals, ymin, ymax)
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

    if Scale.iscategorical(scales, :x)
        xmin -= 0.5
        xmax += 0.5
        xpadding = 0mm
    else
        xpadding = 2mm
    end

    if Scale.iscategorical(scales, :y)
        ymin -= 0.5
        ymax += 0.5
        ypadding = 0mm
    else
        ypadding = 2mm
    end

    width  = xmax - xmin
    height = ymax - ymin

    compose!(
        context(units=UnitBox(
            coord.xflip ? xmax : xmin,
            coord.yflip ? ymin : ymax,
            coord.xflip ? -width : width,
            coord.yflip ? height : -height,
            leftpad=xpadding,
            rightpad=xpadding,
            toppad=ypadding,
            bottompad=ypadding)),
        svgclass("plotpanel"))
end


immutable SubplotGrid <: Gadfly.CoordinateElement
end


function apply_coordinate(coord::SubplotGrid, aess::Vector{Gadfly.Aesthetics},
                          scales::Dict{Symbol, Gadfly.ScaleElement})
    compose!(context(), svgclass("plotpanel"))
end


const subplot_grid = SubplotGrid

end # module Coord

