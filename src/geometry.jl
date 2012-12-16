
module Geom

import Gadfly
import Gadfly.render, Gadfly.element_aesthetics, Gadfly.inherit

using DataFrames

load("Compose.jl")
using Compose

load("Iterators.jl")
import Iterators

# Geometry that renders nothing.
type Nil <: Gadfly.GeometryElement
end

const nil = Nil()

function render(geom::Nil, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
end


# Catchall
function default_statistic(::Gadfly.GeometryElement)
    Gadfly.Stat.identity
end


# Geometry which displays points at given (x, y) positions.
type PointGeometry <: Gadfly.GeometryElement
    default_aes::Gadfly.Aesthetics

    function PointGeometry()
        g = Gadfly.Aesthetics()
        # TODO: these constants should be in Theme
        g.size  = Measure[0.75mm]
        g.color = PooledDataVec(Color[color("steelblue")])
        new(g)
    end
end


const point = PointGeometry()


function element_aesthetics(::PointGeometry)
    [:x, :y, :size, :color]
end

# Check that the x and y aesthetics are properly specified.
#
# Args:
#   aes: some aesthetics
#
# Returns:
#   nothing, throws an error if the aesthetics are misspecified
#
function check_xy(aes::Gadfly.Aesthetics)
    if typeof(aes.x) == Nothing || typeof(aes.y) == Nothing
        error("Both `x` and `y` must be defined for point geometry.")
    end

    if length(aes.x) != length(aes.y)
        error("`x` and `y` must be of equal length point geometry.")
    end

    n = length(aes.x)

    if !is(aes.color, nothing) && length(aes.color) != n
        error("`color` must be the same length as `x` and `y`.")
    end

    if !is(aes.size, nothing) && length(ael.size) != n
        error("`size` must be the same length as `x` and `y`.")
    end
end


# Generate a form for a point geometry.
#
# Args:
#   geom: point geometry.
#   theme: the plot's theme.
#   aes: aesthetics.
#
# Returns:
#   A compose Form.
#
function render(geom::PointGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    check_xy(aes)

    aes = inherit(aes, geom.default_aes)

    forms = Array(Any, length(aes.x))
    for (i, (x, y, s)) in enumerate(zip(aes.x, aes.y, Iterators.cycle(aes.size)))
        forms[i] = circle(x, y, s)
    end

    if length(aes.color) == 1
        form = compose(forms...) << (fill(aes.color[1]) | stroke(nothing))
    else
        form = compose([f << fill(c) for (f, c) in zip(forms, aes.color)]...)
        form << stroke(nothing)
    end
end


# Line geometry connects (x, y) coordinates with lines.
type LineGeometry <: Gadfly.GeometryElement
    default_aes::Gadfly.Aesthetics

    function LineGeometry()
        g = Gadfly.Aesthetics()
        # TODO: these constants should be in Theme
        g.size  = Measure[0.3mm]
        g.color = PooledDataVec(Color[color("steelblue")])
        new(g)
    end
end


const line = LineGeometry()


function element_aesthetics(::LineGeometry)
    [:x, :y, :size, :color]
end



# Render line geometry.
#
# Args:
#   geom: line geometry.
#   theme: the plot's theme.
#   aes: aesthetics.
#
# Returns:
#   A compose Form.
#
function render(geom::LineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    check_xy(aes)

    aes = inherit(aes, geom.default_aes)

    if length(aes.color) == 1
        form = lines({(x, y) for (x, y) in zip(aes.x, aes.y)}...)
        form << (stroke(aes.color[1]) | fill(nothing))
    else
        points = Dict{Color, Array{(Float64, Float64)}}()
        for (x, y, c) in zip(aes.x, aes.x, Iterators.cycle(aes.color))
            if !has(points, c)
                points[c] = Array((Float64, Float64))
            end
            push(points[c], (x, y))
        end

        forms = {}
        for (c, c_points) in points
            form = lines({(x, y) for (x, y) in c_points}...)
            form <<= stroke(c) | fill(nothing)
            push(forms, form)
        end
        compose(forms...)
    end
end


# Bar geometry summarizes data as verticle bars.
type BarGeometry <: Gadfly.GeometryElement
    default_aes::Gadfly.Aesthetics

    function BarGeometry()
        g = Gadfly.Aesthetics()
        g.color = PooledDataVec(Color[color("steelblue")])
        new(g)
    end
end


const bar = BarGeometry()


function element_aesthetics(::BarGeometry)
    [:x, :y, :color]
end


function default_statistic(::BarGeometry)
    Gadfly.Stat.histogram
end

# Render bar geometry.
#
# Args:
#   geom: bar geometry
#   theme: the plot's theme
#   aes: some aesthetics
#
# Returns
#   A compose form.
#
function render(geom::BarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    #check_xy(aes) # TODO: check_x
    aes = Gadfly.inherit(aes, geom.default_aes)

    # Set the bar width to be the minimum distance between to x values, to avoid
    # ovelapping.
    bar_width = Inf
    sorted_x = sort(aes.x)
    for i in 2:length(sorted_x)
        bar_width = min(bar_width, sorted_x[i] - sorted_x[i - 1])
    end

    if !isfinite(bar_width)
        bar_width = 1.0
    end

    bar_width *= theme.bar_width_scale

    forms = {rectangle(x - bar_width/2, 0.0, bar_width, y)
             for (x, y) in zip(aes.x, aes.y)}


    if length(aes.color) == 1
        form = compose(forms...) << fill(aes.color[1])
    else
        form = compose([form << fill(c)
                        for (f, c) in zip(forms, Iterators.cycle(aes.color))]...)
    end

    form << stroke(nothing)
end

end # module Geom

