
module Geom

using Gadfly
using Compose
using DataFrames

import Compose.combine # Prevent DataFrame.combine from taking over.
import Gadfly.render, Gadfly.element_aesthetics, Gadfly.inherit
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
    Gadfly.assert_aesthetics_defined("Geom.point", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataVector(Color[theme.default_color])
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
    Gadfly.assert_aesthetics_defined("Geom.point", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataVector(Color[theme.default_color])
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
    Gadfly.assert_aesthetics_defined("Geom.bar", aes, :x_min, :x_max, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.bar", aes, :x_min, :x_max, :y)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataVector(Color[theme.default_color])
    aes = Gadfly.inherit(aes, default_aes)

    pad = theme.bar_spacing / 2

    forms = {rectangle(x_min*cx + theme.bar_spacing/2, 0.0,
                       (x_max - x_min)*cx - theme.bar_spacing, y)
             for (x_min, x_max, y) in zip(aes.x_min, aes.x_max, aes.y)}

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
    Gadfly.assert_aesthetics_defined("Geom.bar", aes,
                                     :lowor_fence, :lower_hinge, :middle,
                                     :upper_hinge, :upper_fence, :outliers)
    Gadfly.assert_aesthetics_equal_length("Geom.bar", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataVector(Color[theme.default_color])
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


type LabelGeometry <: Gadfly.GeometryElement
end


element_aesthetics(::LabelGeometry) = [:x, :y, :label]


default_statistic(::LabelGeometry) = Gadfly.Stat.identity


const label = LabelGeometry()


# A deferred canvas function for labeling points in a plot. Optimizing label
# placement depends on knowing the absolute size of the containing canvas.
function deferred_label_canvas(aes, theme, box, unit_box)

    # Label layout is non-trivial problem. Quite a few papers and at least one
    # Phd thesis has been written on the topic. The approach here is pretty
    # simple. A label may be placed anywhere surrounding a point or hidden.
    # Simulated annealing is used to try to minimize a penalty, which is equal
    # to the number of overlapping or out fo bounds labels, plus terms
    # penalizing hidden labels.
    #
    # TODO:
    # Penalize to prefer certain label positions over others.

    canvas_width, canvas_height = box.width, box.height

    # This should maybe go in theme? Or should we be using Aesthetics.size?
    padding = 3mm

    point_positions = Array(Tuple, 0)
    for (x, y) in zip(aes.x, aes.y)
        x = absolute_measure(x*cx, unit_box, box)
        y = absolute_measure(y*cy, unit_box, box)
        push(point_positions, (x, y))
    end

    extents = [text_extents(theme.point_label_font,
                            theme.point_label_font_size,
                            label)
               for label in aes.label]

    extents = [(width + padding, height + padding)
               for (width, height) in extents]

    positions = Gadfly.Maybe(BoundingBox)[]
    for (i, (text_width, text_height)) in enumerate(extents)
        x, y = point_positions[i]
        push(positions, BoundingBox(x, y, text_width, text_height))
    end

    # TODO: use Aesthetics.size and/or theme.default_point_size
    for (x, y) in point_positions
        push(positions, BoundingBox(x - 0.5mm, y - 0.5mm, 1mm, 1mm))
        push(extents, (1mm, 1mm))
    end

    n = length(aes.label)

    # Return a box containing every point that the label could possibly overlap.
    function max_extents(i)
        BoundingBox(positions[i].x0 - extents[i][1],
                    positions[i].y0 - extents[i][2],
                    2*extents[i][1],
                    2*extents[i][2])
    end

    # True if two boxes overlap
    function overlaps(a, b)
        if a === nothing || b === nothing
            return false
        end

        a.x0 + a.width  >= b.x0 && a.x0 <= b.x0 + b.width &&
        a.y0 + a.height >= b.y0 && a.y0 <= b.y0 + b.height
    end

    # True if a is fully contained in box.
    function box_contains(a)
        if a === nothing
            return true
        end

        0mm < a.x0 && a.x0 + a.width < box.width &&
        0mm < a.y0 - a.height && a.y0 < box.height
    end

    # Checking for label overlaps is O(n^2). To mitigate these costs, we build a
    # sparse overlap matrix. This also costs O(n^2), but we only have to do it
    # once, rather than every iteration of annealing.
    possible_overlaps = [Array(Int, 0) for _ in 1:length(positions)]

    for j in 1:n
        for i in (j+1):n
            if overlaps(max_extents(i), max_extents(j))
                push(possible_overlaps[i], j)
                push(possible_overlaps[j], i)
            end
        end

        for i in (n+1):length(positions)
            # skip the point box corresponding to label
            if i == j + n
                continue
            end

            if overlaps(positions[i], max_extents(j))
                push(possible_overlaps[i], j)
                push(possible_overlaps[j], i)
            end
        end
    end

    # This variable holds the value of the objective function we wish to
    # minimize. A label overlap is a penalty of 1. Other penaties (out of bounds
    # labels, hidden labels) or calibrated to that.
    total_penalty = 0

    for i in 1:n
        if !box_contains(positions[i])
            total_penalty += theme.label_out_of_bounds_penalty
        end
    end

    for j in 1:n
        for i in possible_overlaps[j]
            if i > j && overlaps(positions[i], positions[j])
                total_penalty += 1
            end
        end
    end

    num_iterations = n * theme.label_placement_iterations
    for k in 1:num_iterations
        if total_penalty == 0
            break
        end
        j = randi(n)

        new_total_penalty = total_penalty

        # Propose flipping the visibility of the label.
        if !is(positions[j], nothing) && rand() < theme.label_visibility_flip_pr
            pos = nothing
            new_total_penalty += theme.label_hidden_penalty

        # Propose a change to label placement.
        else
            if positions[j] === nothing
                new_total_penalty -= theme.label_hidden_penalty
            end

            r = rand()
            point_x, point_y = point_positions[j]
            xspan = extents[j][1]
            yspan = extents[j][2]

            if rand() < 0.5
                xpos = Gadfly.lerp(rand(),
                                   (point_x - 7xspan/8).value,
                                   (point_x - 6xspan/8).value) * mm
            else
                xpos = Gadfly.lerp(rand(),
                                   (point_x - 2xspan/8).value,
                                   (point_x - 1xspan/8).value) * mm
            end

            ypos = Gadfly.lerp(rand(),
                               (point_y - 3yspan/4).value,
                               (point_y - 1yspan/4).value) * mm

            # choose a side
            if r < 0.25 # top
                pos = BoundingBox(xpos, point_y - extents[j][2],
                                  extents[j][1], extents[j][2])
            elseif 0.25 <= r < 0.5 # right
                pos = BoundingBox(point_x, ypos,
                                  extents[j][1], extents[j][2])
            elseif 0.5 <= r < 0.75 # bottom
                pos = BoundingBox(xpos, point_y,
                                  extents[j][1], extents[j][2])
            else # left
                pos = BoundingBox(point_x - extents[j][1], ypos,
                                  extents[j][1], extents[j][2])
            end
        end

        if !box_contains(positions[j])
            new_total_penalty -= theme.label_out_of_bounds_penalty
        end

        if !box_contains(pos)
            new_total_penalty += theme.label_out_of_bounds_penalty
        end

        for i in possible_overlaps[j]
            if overlaps(positions[i], positions[j])
                new_total_penalty -= 1
            end

            if overlaps(positions[i], pos)
                new_total_penalty += 1
            end
        end

        improvement = total_penalty - new_total_penalty
        T = 0.5 * (1.0 - (k / (1 + num_iterations)))
        if improvement >= 0 || rand() < exp(improvement / T)
            positions[j] = pos
            total_penalty = new_total_penalty
        end
    end

    forms = Array(Any, 0)

    # Quite useful for visually debugging this stuff:
    #for position in positions
        #if position === nothing
            #continue
        #end

        #push(forms,
             #rectangle(position.x0, position.y0, position.width, position.height)
             #<< stroke("red") << fill(nothing) << linewidth(0.1mm))
    #end

    for i in 1:n
        if !is(positions[i], nothing)
            # Padding? The direction depends on what side we are on.
            point_x, point_y = point_positions[i]
            x, y = positions[i].x0, positions[i].y0

            x += extents[i][1] / 2
            y += extents[i][2] / 2

            push(forms, text(x, y, aes.label[i], hcenter, vcenter))
        end
    end

    #println("total_penalty = ", total_penalty)

    compose(canvas(convert(Units, unit_box)),
            combine(forms...),
            font(theme.point_label_font),
            fontsize(theme.point_label_font_size),
            fill(theme.point_label_color),
            stroke(nothing))
end


function render(geom::LabelGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.Label", aes, :label, :x, :y)
    deferredcanvas((box, unit_box) -> deferred_label_canvas(aes, theme, box, unit_box))
end


end # module Geom

