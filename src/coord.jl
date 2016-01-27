
module Coord

using Gadfly
using Compat
using Compose
using DataArrays
import Gadfly.Maybe
import Iterators: cycle

export cartesian, polar


# Return the first concrete aesthetic value in one of the given aesthetics
#
# Args:
#   aess: An array of Aesthetics to search through.
#   vars: Aesthetic variables to search through.
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
    T = @compat(Union{})
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


# Cartesian
# ---------

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

    function Cartesian(
            xvars=[:x, :xmin, :xmax, :xintercept],
            yvars=[:y, :ymin, :ymax, :yintercept, :middle,
                   :lower_hinge, :upper_hinge, :lower_fence, :upper_fence, :outliers];
            xflip::Bool=false, yflip::Bool=false,
            xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing,
            fixed=false, aspect_ratio=nothing, raster=false)
        if isa(aspect_ratio, Real)
            aspect_ratio = convert(Float64, aspect_ratio)
        end
        new(xvars, yvars, xmin, xmax, ymin, ymax, xflip, yflip, fixed,
            aspect_ratio, raster)
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


# Polar
# -----

# Polar coordinates with position given by the r and theta aesthetics.
#
# Args:
#   rhovars: Radial aesthetics to consider when choosing bounds.
#   phivars: Angular aesthetics to consider when choosing bounds.
#   xmin, xmax, ymin, ymax:
#     Force a particular x or y bound, rather than trying to choose it
#     from the data.
#
#
immutable Polar <: Gadfly.CoordinateElement
    rhovars::Vector{Symbol}
    phivars::Vector{Symbol}
    xmin
    xmax
    ymin
    ymax
    xflip::Bool
    yflip::Bool
    fixed::Bool
    aspect_ratio::@compat(Union{(@compat Void), Float64})
    raster::Bool

    function Polar(
            rhovars=[:rho],
            phivars=[:phi];
            xflip::Bool=false, yflip::Bool=false,
            xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing,
            fixed=false, aspect_ratio=nothing, raster=false)
        if isa(aspect_ratio, Real)
            aspect_ratio = convert(Float64, aspect_ratio)
        end
        new(rhovars, phivars, xmin, xmax, ymin, ymax, xflip, yflip, fixed,
            aspect_ratio, raster)
    end
end


const polar = Polar


cartesian_to_polar(x, y) = (hypot(x, y), atan2(y, x))
polar_to_cartesian(ρ, ϕ) = (ρ * cos(ϕ), ρ * sin(ϕ))


# Produce a context with suitable polar coordinates.
#
# Args:
#   coord: polar coordinate instance.
#
# Returns:
#   A compose Canvas.
#
function apply_coordinate(coord::Polar, aess::Vector{Gadfly.Aesthetics},
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

    rhomin = rhomax = first_concrete_aesthetic_value(aess, coord.rhovars)
    phimin = phimax = first_concrete_aesthetic_value(aess, coord.phivars)
    xmin, ymin = polar_to_cartesian(rhomin, phimin)
    xmax, ymax = polar_to_cartesian(rhomax, phimax)

    if rhomin != nothings
        for rhovar in coord.rhovars, phivar in coord.phivars
            for aes in aess
                rhovals = getfield(aes, rhovar)
                phivals = getfield(aes, phivar)
                if rhovals === nothing || phivals === nothing
                    continue
                end

                if !isa(rhovals, AbstractArray)
                    rhovals = [rhovals]
                end
                if !isa(phivals, AbstractArray)
                    phivals = [phivals]
                end

                if length(rhovals) != length(phivals)
                    error("Aesthetics for rho and phi must have the same length.")
                end

                xvals = [ρ * cos(ϕ) for (ρ, ϕ) in zip(rhovals, phivals)]
                yvals = [ρ * sin(ϕ) for (ρ, ϕ) in zip(rhovals, phivals)]

                xmin, xmax = Gadfly.concrete_minmax(xvals, xmin, xmax)
                ymin, ymax = Gadfly.concrete_minmax(yvals, ymin, ymax)
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


# Subplot Grid
# ------------

immutable SubplotGrid <: Gadfly.CoordinateElement
end


function apply_coordinate(coord::SubplotGrid, aess::Vector{Gadfly.Aesthetics},
                          scales::Dict{Symbol, Gadfly.ScaleElement})
    compose!(context(), svgclass("plotpanel"))
end


const subplot_grid = SubplotGrid

end # module Coord
