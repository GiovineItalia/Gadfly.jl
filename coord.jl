
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
        new(spec, Inf, -Inf, Inf, -Inf)
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
                if x < fittedcoord.xmin
                    fittedcoord.xmin = x
                end

                if x > fittedcoord.xmax
                    fittedcoord.xmax = x
                end
            end
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
                if y < fittedcoord.ymin
                    fittedcoord.ymin = y
                end

                if y > fittedcoord.ymax
                    fittedcoord.ymax = y
                end
            end
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

    Canvas(Units(coord.xmin - xpadding, coord.ymin - ypadding,
                 coord.xmax - coord.xmin + 2xpadding,
                 coord.ymax - coord.ymin + 2ypadding))
end


