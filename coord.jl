
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

const coord_cartesian = CartesianCoordinate([:x, :xticks],
                                            [:y, :yticks])


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


function apply_coord(coord::FittedCartesianCoordinate, parent_aes::Aesthetics)
    aes = copy(parent_aes)

    # Set xmin, xmax, ymin, ymax if not set.
    if is(aes.xmin, nothing)
        aes.xmin = coord.xmin
    end

    if is(aes.xmax, nothing)
        aes.xmax = coord.xmax
    end

    if is(aes.ymin, nothing)
        aes.ymin = coord.ymin
    end

    if is(aes.ymax, nothing)
        aes.ymax = coord.ymax
    end

    xspan = aes.xmax - aes.xmin

    for var in coord.spec.xvars
        if is(getfield(aes, var), nothing)
            continue
        end

        xs = Array(Float64, length(getfield(aes, var)))
        for (x, i) in enumerate(getfield(aes, var))
            xs[i] = (aes.xmin + x) / xspan
        end
        setfield(aes, var, xs)
    end

    yspan = aes.ymax - aes.ymin

    for var in coord.spec.yvars
        if is(getfield(aes, var), nothing)
            continue
        end

        ys = Array(Float64, length(getfield(aes, var)))
        for (y, i) in enumerate(getfield(aes, var))
            ys[i] = (aes.ymin + y) / yspan
        end
        setfield(aes, var, ys)
    end

    aes
end



