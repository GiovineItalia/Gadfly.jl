
require("compose.jl")

abstract Coordinate
typealias Coordinates Vector{Coordinate}


abstract FittedCoordinate
typealias FittedCoordinates Vector{FittedCoordinate}


# Here's the latest issue: Similar to what we did with scales, we need to fit
# the coorditates on all the data is one go. This is difficult since Aesthetics
# is strictly vectors. Possible solutions?


function fit_coords(coords::Coordinates, aess::Aesthetics...)
    fittedcoords = Array(FittedCoordinate, length(coords))

    for (coord, i) in enumerate(coords)
        fittedcoords[i] = fit_coord(coord, aess...)
    end

    fittedcoords
end


function apply_coords(coords::FittedCoordinates, parent_aes::Aesthetics)
    aes = parent_aes
    for coord in coords
        aes = apply_coord(coord, aes)
    end

    aes
end




# How does this operate on other aesthetics on the x-axis. For example, how to
# xmin/xmax it mapped?

# Let's say we want to draw some motherfucking rectangles.
# 1. we pass data to xmin, xmax, ymin, ymax
# 2. we specify (or the plot defaults to) scale_x_continuous, scale_y_continuous
# 3. xmin, xmax, ymin, ymax get mapped by ContinuousScale to themselves.
# 4. (statistics, transformations, here maybe )
# 5. now CartesianCoordinate gets ahold, and does what exactly?
# 6. finally PointGeometry should be passed points on [0.0, 1.0]
#    to draw.

# Things to consider:
# How are polar coordinates supposed to work? BarGeometry has to do something
# completely different (draw arcs) if the coordinate system is different.



type CartesianCoordinate <: Coordinate
    xvars::Vector{Symbol}
    yvars::Vector{Symbol}
end

const coord_cartesian = CartesianCoordinate([:x],
                                            [:y])


type FittedCartesianCoordinate <: FittedCoordinate
    spec::CartesianCoordinate
    xmin::Float64
    xmax::Float64
    ymin::Float64
    ymax::Float64

    function FittedCartesianCoordinate(spec::CartesianCoordinate)
        new(spec, Inf, 0.0, Inf, 0.0)
    end
end


function fit_coord(coord::CartesianCoordinate, aess::Aesthetics...)
    fittedcoord = FittedCartesianCoordinate(coord)

    for aes in aess
        for var in coord.xvars
            if is(getfield(aes, var), nothing)
                continue
            end

            for x in getfield(aes, var)
                fittedcoord.xmin = min(fittedcoord.xmin, x)
                fittedcoord.xmax = max(fittedcoord.xmax, x)
            end
        end

        for (x, _) in aes.xticks
            fittedcoord.xmin = min(fittedcoord.xmin, x)
            fittedcoord.xmax = max(fittedcoord.xmax, x)
        end
    end


    if !isfinite(fittedcoord.xmin)
        fittedcoord.xmin = 0.0
    end

    if !isfinite(fittedcoord.xmax)
        fittedcoord.xmax = 1.0
    end


    for aes in aess
        for var in coord.yvars
            if is(getfield(aes, var), nothing)
                continue
            end

            for y in getfield(aes, var)
                fittedcoord.ymin = min(fittedcoord.ymin, y)
                fittedcoord.ymax = max(fittedcoord.ymax, y)
            end
        end

        for (y, _) in aes.yticks
            fittedcoord.ymin = min(fittedcoord.ymin, y)
            fittedcoord.ymax = max(fittedcoord.ymax, y)
        end
    end

    if !isfinite(fittedcoord.ymin)
        fittedcoord.ymin = 0.0
    end

    if !isfinite(fittedcoord.ymax)
        fittedcoord.ymax = 1.0
    end

    fittedcoord
end


function apply_coord(coord::FittedCartesianCoordinate)
    xspan = coord.xmax - coord.xmin
    xpadding = 0.03 * xspan

    yspan = coord.ymax - coord.ymin
    ypadding = 0.03 * yspan

    width  = coord.xmax - coord.xmin + 2xpadding
    height = coord.ymax - coord.ymin + 2ypadding

    Canvas(Units(coord.xmin - xpadding, height - ypadding,
                 width, -height))
end


