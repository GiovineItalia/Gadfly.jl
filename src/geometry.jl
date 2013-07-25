
module Geom

using Color
using Compose
using DataFrames
using Gadfly

import Compose.combine # Prevent DataFrame.combine from taking over.
import Gadfly.render, Gadfly.element_aesthetics, Gadfly.inherit, Gadfly.escape_id
import Iterators.cycle, Iterators.product, Iterators.distinct


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
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    default_aes.size = Measure[theme.default_point_size]
    aes = inherit(aes, default_aes)

    lw0 = convert(Compose.SimpleMeasure{Compose.MillimeterUnit}, theme.line_width)
    lw1 = 10 * lw0
    compose(circle(aes.x, aes.y, aes.size),
            fill(aes.color),
            stroke([theme.highlight_color(c) for c in aes.color]),
            linewidth(theme.line_width),
            d3embed(@sprintf(".on(\"mouseover\", geom_point_mouseover(%0.2f), false)",
                             lw1.value)),
            d3embed(@sprintf(".on(\"mouseout\", geom_point_mouseover(%0.2f), false)",
                             lw0.value)),
            svgclass([@sprintf("geometry color_%s", escape_id(aes.color_label(c)))
                      for c in aes.color]))
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
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    aes = inherit(aes, default_aes)

    if length(aes.color) == 1
        points = {(x, y) for (x, y) in zip(aes.x, aes.y)}
        sort!(points)
        form = lines(points...) <<
               stroke(aes.color[1]) <<
               svgclass("geometry")
    else
        # group points by color
        points = Dict{ColorValue, Array{(Float64, Float64),1}}()
        for (x, y, c) in zip(aes.x, aes.y, cycle(aes.color))
            if !haskey(points, c)
                points[c] = Array((Float64, Float64),0)
            end
            push!(points[c], (x, y))
        end

        forms = Array(Any, length(points))
        for (i, (c, c_points)) in enumerate(points)
            sort!(c_points)
            forms[i] = lines({(x, y) for (x, y) in c_points}...) <<
                            stroke(c) <<
                            svgclass(@sprintf("geometry color_%s", escape_id(aes.color_label(c))))
        end
        form = combine(forms...)
    end

    form << fill(nothing) << linewidth(theme.line_width)
end


# Bar geometry summarizes data as vertical bars.
type BarGeometry <: Gadfly.GeometryElement
end


const bar = BarGeometry()
const histogram = BarGeometry()


function element_aesthetics(::BarGeometry)
    [:x, :y, :color]
end


function default_statistic(::BarGeometry)
    Gadfly.Stat.histogram
end


# Render bar geometry with a discrete x axis.
function render_discrete_bar(geom::BarGeometry,
                             theme::Gadfly.Theme,
                             aes::Gadfly.Aesthetics)
    # Group by x-axis.
    bars = Dict()
    for (x, y, c) in zip(aes.x, aes.y, cycle(aes.color.refs))
        if !haskey(bars, x)
            bars[x] = {}
        end
        push!(bars[x], (c, y))
    end
    ncolors = length(levels(aes.color))
    pad = 2mm
    barwidth = (1.0cx - pad) / ncolors

    bar_form = empty_form
    for (x, cys) in bars
        for (cref, y) in sort(cys)
            c = aes.color.pool[cref]
            hc = theme.highlight_color(c)
            bar_form |=
                compose(rectangle((x - 0.5)cx + pad/2 + (cref-1) * barwidth, 0.0,
                                  barwidth, y),
                        fill(c))
        end
    end

    compose(canvas(units_inherited=true),
            bar_form,
            svgattribute("shape-rendering", "crispEdges"),
            stroke(nothing))
end


# Render bar geometry with a continuous x axis.
function render_continuous_bar(geom::BarGeometry,
                               theme::Gadfly.Theme,
                               aes::Gadfly.Aesthetics)
    pad = theme.bar_spacing / 2
    bar_form = empty_form

    if aes.color === nothing
        for (x_min, x_max, y) in zip(aes.x_min, aes.x_max, aes.y)
            annotation_id = Gadfly.unique_svg_id()
            geometry_id = Gadfly.unique_svg_id()

            bar_form |= compose(rectangle(x_min*cx + theme.bar_spacing/2, 0.0,
                                          (x_max - x_min)*cx - theme.bar_spacing, y),
                                svgid(geometry_id), svgclass("geometry"))
        end
    else
        stack_height = Dict()
        for x_min in aes.x_min
            stack_height[x_min] = 0.0
        end

        zeros(Int, length(aes.x_min))
        for (x_min, x_max, y, c) in zip(aes.x_min, aes.x_max, aes.y, aes.color)
            annotation_id = Gadfly.unique_svg_id()
            geometry_id = Gadfly.unique_svg_id()
            bar_form |= compose(rectangle(x_min*cx + theme.bar_spacing/2,
                                          stack_height[x_min],
                                          (x_max - x_min)*cx - theme.bar_spacing,
                                          y),
                                fill(c),
                                svgid(geometry_id),
                                svgclass("geometry"))
            stack_height[x_min] += y
        end
    end

    compose(canvas(units_inherited=true),
            stroke(nothing),
            (bar_form,
                fill(theme.default_color),
                svgattribute("shape-rendering", "crispEdges")))
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
    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    aes = Gadfly.inherit(aes, default_aes)

    if aes.x_min === nothing
        Gadfly.assert_aesthetics_defined("Geom.bar", aes, :x, :y)
        Gadfly.assert_aesthetics_equal_length("Geom.bar", aes, :x, :y)
        render_discrete_bar(geom, theme, aes)
    else
        Gadfly.assert_aesthetics_defined("Geom.bar", aes, :x_min, :x_max, :y)
        Gadfly.assert_aesthetics_equal_length("Geom.bar", aes, :x_min, :x_max, :y)
        render_continuous_bar(geom, theme, aes)
    end
end


type RectangularBinGeometry <: Gadfly.GeometryElement
end


const rectbin = RectangularBinGeometry()


function element_aesthetics(::RectangularBinGeometry)
    [:x, :y, :x_min, :x_max, :y_min, :y_max, :color]
end



# Render a rectbin geometry with continuous x_min/x_max y_min/y_max coordinates.
function render_continuous_rectbin(geom::RectangularBinGeometry,
                                   theme::Gadfly.Theme,
                                   aes::Gadfly.Aesthetics)
    n = length(aes.x_min)
    forms = Array(Compose.Form, 0)

    for (i, c) in zip(1:n, cycle(aes.color))
        if !isna(c)
            push!(forms, rectangle(aes.x_min[i], aes.y_min[i],
                                  (aes.x_max[i] - aes.x_min[i])*cx - theme.bar_spacing,
                                  (aes.y_max[i] - aes.y_min[i])*cy + theme.bar_spacing) <<
                             fill(c) << svgclass("geometry"))
        end
    end

    compose(combine(forms...),
            stroke(nothing),
            svgattribute("shape-rendering", "crispEdges"))
end


# Rendere a rectbin geometry with discrete x/y coordinaes.
function render_discrete_rectbin(geom::RectangularBinGeometry,
                                   theme::Gadfly.Theme,
                                   aes::Gadfly.Aesthetics)
    n = length(aes.x)
    forms = Array(Compose.Form, 0)
    for (i, c) in zip(1:n, cycle(aes.color))
        if !isna(c)
            x, y = aes.x[i], aes.y[i]
            push!(forms, compose(rectangle(x - 0.5, y - 0.5, 1.0, 1.0),
                                 fill(c),
                                 svgclass("geometry")))
        end
    end

    compose(combine(forms...),
            stroke(nothing),
            svgattribute("shape-rendering", "crispEdges"))
end


# Render rectangular bin (e.g., heatmap) geometry.
#
# Args:
#   geom: rectbin geometry
#   theme: the plot's theme
#   aes: some aesthetics
#
# Returns
#   A compose form.
#
function render(geom::RectangularBinGeometry,
                theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
    aes = inherit(aes, default_aes)

    if aes.x_min === nothing
        Gadfly.assert_aesthetics_defined("Geom.bar", aes, :x, :y)
        Gadfly.assert_aesthetics_equal_length("Geom.bar", aes, :x, :y)
        render_discrete_rectbin(geom, theme, aes)
    else
        Gadfly.assert_aesthetics_defined("Geom.bar",
                                         aes, :x_min, :x_max, :y_min, :y_max)
        Gadfly.assert_aesthetics_equal_length("Geom.bar",
                                              aes, :x_min, :x_max,
                                              :y_min, :y_max)
        render_continuous_rectbin(geom, theme, aes)
    end
end


function default_statistic(::RectangularBinGeometry)
    Gadfly.Stat.rectbin
end


type BoxplotGeometry <: Gadfly.GeometryElement
end


const boxplot = BoxplotGeometry()

element_aesthetics(::BoxplotGeometry) = [:x, :y, :color]

default_statistic(::BoxplotGeometry) = Gadfly.Stat.boxplot

function render(geom::BoxplotGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.bar", aes,
                                     :lower_fence, :lower_hinge, :middle,
                                     :upper_hinge, :upper_fence, :outliers)
    Gadfly.assert_aesthetics_equal_length("Geom.bar", aes,
                                     :lower_fence, :lower_hinge, :middle,
                                     :upper_hinge, :upper_fence, :outliers)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(ColorValue[theme.default_color])
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
    middle_forms = Compose.Form[]

    r = theme.default_point_size
    bw = 1.0cx - theme.boxplot_spacing

    # TODO: handle color non-nothing color

    for (lf, lh, mid, uh, uf, outliers, x, cref) in aes_iter
        c = aes.color.pool[cref]
        sc = theme.highlight_color(c) # stroke color
        mc = theme.middle_color(c) # middle color

        # Middle
        push!(middle_forms, compose(lines((x - 1/6, mid), (x + 1/6, mid)),
                                    linewidth(theme.line_width), stroke(mc)))

        # Box
        push!(forms, compose(rectangle(x*cx - bw/2, lh, bw, uh - lh),
                            fill(c), stroke(sc),
                            linewidth(theme.highlight_width)))

        # Whiskers
        push!(forms, compose(lines((x, lh), (x, lf)),
                            linewidth(theme.line_width), stroke(sc)))

        push!(forms, compose(lines((x, uh), (x, uf)),
                            linewidth(theme.line_width), stroke(sc)))

        # Fences
        push!(forms, compose(lines((x - 1/6, lf), (x + 1/6, lf)),
                            linewidth(theme.line_width), stroke(sc)))

        push!(forms, compose(lines((x - 1/6, uf), (x + 1/6, uf)),
                            linewidth(theme.line_width), stroke(sc)))

        # Outliers
        if !isempty(outliers)
            push!(forms, compose(combine([circle(x, y, r) for y in outliers]...),
                                fill(c), stroke(sc)))
        end
    end

    compose(canvas(units_inherited=true),
            (canvas(units_inherited=true), combine(forms...)),
            (canvas(units_inherited=true, order=1), combine(middle_forms...)),
            svgclass("geometry"))
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
        push!(point_positions, (x, y))
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
        push!(positions, BoundingBox(x, y, text_width, text_height))
    end

    # TODO: use Aesthetics.size and/or theme.default_point_size
    for (x, y) in point_positions
        push!(positions, BoundingBox(x - 0.5mm, y - 0.5mm, 1mm, 1mm))
        push!(extents, (1mm, 1mm))
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
                push!(possible_overlaps[i], j)
                push!(possible_overlaps[j], i)
            end
        end

        for i in (n+1):length(positions)
            # skip the point box corresponding to label
            if i == j + n
                continue
            end

            if overlaps(positions[i], max_extents(j))
                push!(possible_overlaps[i], j)
                push!(possible_overlaps[j], i)
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
        j = rand(1:n)

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

        #push!(forms,
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

            push!(forms, text(x, y, aes.label[i], hcenter, vcenter) <<
                    svgclass("geometry"))
        end
    end

    #println("total_penalty = ", total_penalty)

    compose(canvas(unit_box=convert(Units, unit_box)),
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

