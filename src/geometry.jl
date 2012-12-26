
module Geom

import Gadfly
import Gadfly.render, Gadfly.element_aesthetics, Gadfly.inherit

using DataFrames

require("Compose")
using Compose

require("Iterators")
import Iterators.cycle

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

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataVec(Color[theme.default_color])
    default_aes.size = Measure[theme.default_point_size]
    aes = inherit(aes, default_aes)

    # organize by color
    points = Dict{Color, Array{Tuple,1}}()
    for (x, y, c, s) in zip(aes.x, aes.y,
                            cycle(aes.color),
                            cycle(aes.size))
        if !has(points, c)
            points[c] = Array(Tuple,0)
        end
        push(points[c], (x, y, s))
    end

    form = combine([combine([circle(x, y, s) for (x, y, s) in xys]...) <<
                        fill(c) <<
                        stroke(theme.highlight_color(c)) <<
                        svgclass(@sprintf("color_group_%s", aes.color_label(c)))
                    for (c, xys) in points]...)

    form << stroke(nothing) << linewidth(theme.highlight_width)
end


# Line geometry connects (x, y) coordinates with lines.
type LineGeometry <: Gadfly.GeometryElement
end


const line = LineGeometry()


function element_aesthetics(::LineGeometry)
    [:x, :y, :color]
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

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataVec(Color[theme.default_color])
    aes = inherit(aes, default_aes)

    if length(aes.color) == 1
        form = lines({(x, y) for (x, y) in zip(aes.x, aes.y)}...) <<
               stroke(aes.color[1])
    else
        # group points by color
        points = Dict{Color, Array{(Float64, Float64),1}}()
        for (x, y, c) in zip(aes.x, aes.y, cycle(aes.color))
            if !has(points, c)
                points[c] = Array((Float64, Float64),0)
            end
            push(points[c], (x, y))
        end

        forms = Array(Any, length(points))
        for (i, (c, c_points)) in enumerate(points)
            forms[i] = lines({(x, y) for (x, y) in c_points}...) <<
                            stroke(c) <<
                            svgclass(@sprintf("color_group_%s", aes.color_label(c)))
        end
        form = combine(forms...)
    end

    form << fill(nothing) << linewidth(theme.line_width)
end


# Bar geometry summarizes data as verticle bars.
type BarGeometry <: Gadfly.GeometryElement
    default_aes::Gadfly.Aesthetics

    function BarGeometry()
        g = Gadfly.Aesthetics()
        # TODO: This should be in theme.
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
    if typeof(aes.x) == Nothing
        error("`x' must be defined for bar geometry.")
    end

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
        form = combine(forms...) << fill(aes.color[1])
    else
        form = combine([form << fill(c)
                        for (f, c) in zip(forms, cycle(aes.color))]...)
    end

    form << stroke(nothing)
end


type BoxplotGeometry <: Gadfly.GeometryElement
end


const boxplot = BoxplotGeometry()

element_aesthetics(::BoxplotGeometry) = [:x, :y, :color]

default_statistic(::BoxplotGeometry) = Gadfly.Stat.boxplot

function render(geom::BoxplotGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataVec(Color[theme.default_color])
    default_aes.x = Float64[1]
    aes = inherit(aes, default_aes)

    aes_iter = zip(aes.lower_fence,
                   aes.lower_hinge,
                   aes.middle,
                   aes.upper_hinge,
                   aes.upper_fence,
                   aes.outliers,
                   cycle(aes.x),
                   cycle(aes.color.refs))

    forms = Compose.Form[]
    r = theme.default_point_size
    bw = theme.bar_width_scale

    # TODO: handle color non-nothing color

    for (lf, lh, mid, uh, uf, outliers, x, cref) in aes_iter
        c = aes.color.pool[cref]
        sc = theme.highlight_color(c) # stroke color
        mc = theme.middle_color(c) # middle color
        # Box
        push(forms, compose(rectangle(x - bw/2, lh, bw, uh - lh),
                            fill(c), stroke(sc),
                            linewidth(theme.highlight_width)))

        # Middle
        push(forms, compose(lines((x - 1/6, mid), (x + 1/6, mid)),
                            linewidth(theme.line_width), stroke(mc)))

        # Whiskers
        push(forms, compose(lines((x, lh), (x, lf)),
                            linewidth(theme.line_width), stroke(sc)))

        push(forms, compose(lines((x, uh), (x, uf)),
                            linewidth(theme.line_width), stroke(sc)))

        # Fences
        push(forms, compose(lines((x - 1/6, lf), (x + 1/6, lf)),
                            linewidth(theme.line_width), stroke(sc)))

        push(forms, compose(lines((x - 1/6, uf), (x + 1/6, uf)),
                            linewidth(theme.line_width), stroke(sc)))

        # Outliers
        if !isempty(outliers)
            push(forms, compose(combine([circle(x, y, r) for y in outliers]...),
                                fill(c), stroke(sc)))
        end
    end

    form = combine(forms...)


end

end # module Geom

