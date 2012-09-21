
require("compose.jl")
require("aesthetics.jl")
require("theme.jl")


abstract Geometry

# Geometry that does renders nothing.
type NilGeometry <: Geometry
end

function render(geom::NilGeometry, theme::Theme, aes::Aesthetics) end

# Geometry which displays points at given (x, y) positions.
type PointGeometry <: Geometry
    default_aes::Aesthetics

    function PointGeometry()
        g = Aesthetics()
        # TODO: these constants should be in Theme
        g.size  = Measure[0.5mm]
        g.color = Color[color("steelblue")]
        new(g)
    end
end

const geom_point = PointGeometry()


# Check that the x and y aesthetics are properly specified.
#
# Args:
#   aes: some aesthetics
#
# Returns:
#   nothing, throws an error if the aesthetics are misspecified
#
function check_xy(aes::Aesthetics)
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
function render(geom::PointGeometry, theme::Theme, aes::Aesthetics)
    check_xy(aes)

    aes = inherit(aes, geom.default_aes)

    forms = Array(Any, n)
    for ((x, y, s), i) in enumerate(zip(aes.x, aes.y, cycle(aes.size)))
        forms[i] = Circle(x, y, s)
    end

    if length(aes.color) == 1
        form = compose!(forms..., Fill(aes.color[1]))
    else
        for (f, c) in zip(forms, aes.color)
            compose!(f, Fill(c))
        end
        form = compose!(forms...)
    end

    compose!(form, Stroke(nothing))
end


# Line geometry connects (x, y) coordinates with lines.
type LineGeometry <: Geometry
    default_aes::Aesthetics

    function LineGeometry()
        g = Aesthetics()
        # TODO: these constants should be in Theme
        g.size  = Measure[0.5mm]
        g.color = Color[color("steelblue")]
        new(g)
    end
end


const geom_line = LineGeometry()


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
function render(geom::LineGeometry, theme::Theme, aes::Aesthetics)
    println("render line geom")

    check_xy(aes)

    aes = inherit(aes, geom.default_aes)

    if length(aes.color) == 1
        compose!(Lines({(x, y) for (x, y) in zip(aes.x, aes.y)}...),
                 Stroke(aes.color[1]), Fill(nothing))
    else
        # TODO: How does this work?
        # Which line gets the point? Do we do a gradient
        # between the two?
    end
end


# Bar geometry summarizes data as verticle bars.
type BarGeometry <: Geometry
    default_aes::Aesthetics

    function BarGeometry()
        g = Aesthetics()
        g.color = Color[color("steelblue")]
        new(g)
    end
end


const geom_bar = BarGeometry()


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
function render(geom::BarGeometry, theme::Theme, aes::Aesthetics)
    check_xy(aes)
    aes = inherit(aes, geom.default_aes)

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

    forms = {Rectangle(x - bar_width/2, 0.0, bar_width, y)
             for (x, y) in zip(aes.x, aes.y)}


    if length(aes.color) == 1
        form = compose!(forms, Fill(aes.color[1]))
    else
        for (form, c) in zip(forms, cycle(aes.color))
            compose!(form, Fill(c))
        end
        form = compose!(forms)
    end

    compose!(form, Stroke(nothing))
end



