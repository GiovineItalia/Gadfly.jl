module Coord

using Gadfly
using Compat
using Compose
using DataArrays
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
    xflip::Bool
    yflip::Bool
    fixed::Bool
    aspect_ratio::@compat(Union{(@compat Void), Float64})
    raster::Bool

    Cartesian(xvars, yvars, xmin, xmax, ymin, ymax, xflip, yflip, fixed, aspect_ratio, raster) =
            new(xvars, yvars, xmin, xmax, ymin, ymax, xflip, yflip, fixed,
                isa(aspect_ratio, Real) ? Float64(aspect_ratio) : aspect_ratio, raster)
end

function Cartesian(
        xvars=[:x, :xmin, :xmax, :xintercept],
        yvars=[:y, :ymin, :ymax, :yintercept, :middle,
               :lower_hinge, :upper_hinge, :lower_fence, :upper_fence, :outliers];
        xflip=false, yflip=false,
        xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing,
        fixed=false, aspect_ratio=nothing, raster=false)
    Cartesian(xvars, yvars, xmin, xmax, ymin, ymax, xflip, yflip, fixed, aspect_ratio, raster)
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
function first_concrete_aesthetic_value(aess::Vector{Gadfly.Aesthetics}, vars::Vector{Symbol})
    T = aesthetics_type(aess, vars)
    for var in vars
        for aes in aess
            vals = getfield(aes, var)
            vals === nothing && continue

            if !isa(vals, AbstractArray)
                vals = [vals]
            end

            if var == :outliers
                for outlier_vals in aes.outliers
                    for val in outlier_vals
                        Gadfly.isconcrete(val) && return convert(T, val)
                    end
                end
                continue
            end

            for val in vals
                Gadfly.isconcrete(val) && return convert(T, val)
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
    T = @compat(Union{})
    for var in vars
        for aes in aess
            vals = getfield(aes, var)
            vals === nothing && continue

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
    pad_categorical_x = Nullable{Bool}()
    pad_categorical_y = Nullable{Bool}()
    for aes in aess
        if !isnull(aes.pad_categorical_x)
            if isnull(pad_categorical_x)
                pad_categorical_x = aes.pad_categorical_x
            else
                pad_categorical_x = Nullable(get(pad_categorical_x) || get(aes.pad_categorical_x))
            end
        end
        if !isnull(aes.pad_categorical_y)
            if isnull(pad_categorical_y)
                pad_categorical_y = aes.pad_categorical_y
            else
                pad_categorical_y = Nullable(get(pad_categorical_y) || get(aes.pad_categorical_y))
            end
        end
    end

    xmin = xmax = first_concrete_aesthetic_value(aess, coord.xvars)

    if xmin != nothing
        for var in coord.xvars
            for aes in aess
                vals = getfield(aes, var)
                vals === nothing && continue

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
                vals === nothing && continue

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

    xviewmin = xviewmax = yviewmin = yviewmax = nothing

    # viewmin/max that is set explicitly should override min/max
    for aes in aess
        if aes.xviewmin != nothing
            xviewmin = xviewmin === nothing ? aes.xviewmin : min(xviewmin, aes.xviewmin)
        end

        if aes.xviewmax != nothing
            xviewmax = xviewmax === nothing ? aes.xviewmax : max(xviewmax, aes.xviewmax)
        end

        if aes.yviewmin != nothing
            yviewmin = yviewmin === nothing ? aes.yviewmin : min(yviewmin, aes.yviewmin)
        end

        if aes.yviewmax != nothing
            yviewmax = yviewmax === nothing ? aes.yviewmax : max(yviewmax, aes.yviewmax)
        end
    end

    xmax = xviewmax === nothing ? xmax : max(xmax, xviewmax)
    xmin = xviewmin === nothing ? xmin : min(xmin, xviewmin)
    ymax = yviewmax === nothing ? ymax : max(ymax, yviewmax)
    ymin = yviewmin === nothing ? ymin : min(ymin, yviewmin)

    # Hard limits set in Coord should override everything else
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

    xpadding = Scale.iscategorical(scales, :x) ? 0mm : 2mm
    ypadding = Scale.iscategorical(scales, :y) ? 0mm : 2mm

    if Scale.iscategorical(scales, :x) && (isnull(pad_categorical_x) || get(pad_categorical_x))
        xmin -= 0.5
        xmax += 0.5
    end

    if Scale.iscategorical(scales, :y) && (isnull(pad_categorical_y) || get(pad_categorical_y))
        ymin -= 0.5
        ymax += 0.5
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
            bottompad=ypadding),
            raster=coord.raster),
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
