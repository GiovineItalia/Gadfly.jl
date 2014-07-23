
immutable LabelGeometry <: Gadfly.GeometryElement
    hide_overlaps::Bool

    function LabelGeometry(;hide_overlaps::Bool=true)
        new(hide_overlaps)
    end
end


element_aesthetics(::LabelGeometry) = [:x, :y, :label]


default_statistic(::LabelGeometry) = Gadfly.Stat.identity()


const label = LabelGeometry


# A deferred context function for labeling points in a plot. Optimizing label
# placement depends on knowing the absolute size of the containing context.
function deferred_label_context(geom::LabelGeometry,
                                aes::Gadfly.Aesthetics,
                                theme::Gadfly.Theme,
                                drawctx::ParentDrawContext)

    # Label layout is non-trivial problem. Quite a few papers and at least one
    # Phd thesis has been written on the topic. The approach here is pretty
    # simple. A label may be placed anywhere surrounding a point or hidden.
    # Simulated annealing is used to try to minimize a penalty, which is equal
    # to the number of overlapping or out fo bounds labels, plus terms
    # penalizing hidden labels.
    #
    # TODO:
    # Penalize to prefer certain label positions over others.

    parent_transform = drawctx.t
    units = drawctx.units
    parent_box = drawctx.box

    canvas_width, canvas_height = parent_box.width, parent_box.height

    # This should maybe go in theme? Or should we be using Aesthetics.size?
    padding = 2mm

    point_positions = Array(Tuple, 0)
    for (x, y) in zip(aes.x, aes.y)
        x = Compose.absolute_x_position(x*cx, parent_transform, units,
                                        parent_box)
        y = Compose.absolute_y_position(y*cy, parent_transform, units,
                                        parent_box)
        x -= parent_box.x0
        y -= parent_box.y0
        push!(point_positions, (x, y))
    end

    extents = text_extents(theme.point_label_font,
                           theme.point_label_font_size,
                           aes.label...)
    extents = [(width + padding, height + padding)
               for (width, height) in extents]

    positions = Gadfly.Maybe(AbsoluteBoundingBox)[]
    for (i, (text_width, text_height)) in enumerate(extents)
        x, y = point_positions[i]
        push!(positions, AbsoluteBoundingBox(
                x, y, text_width.abs, text_height.abs))
    end

    # TODO: use Aesthetics.size and/or theme.default_point_size
    for (x, y) in point_positions
        push!(positions, AbsoluteBoundingBox(x - 0.5, y - 0.5, 1.0, 1.0))
        push!(extents, (1mm, 1mm))
    end

    n = length(aes.label)

    # Return a box containing every point that the label could possibly overlap.
    function max_extents(i)
        AbsoluteBoundingBox(positions[i].x0 - extents[i][1].abs,
                            positions[i].y0 - extents[i][2].abs,
                            2*extents[i][1].abs,
                            2*extents[i][2].abs)
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

        0 < a.x0 && a.x0 + a.width < parent_box.width &&
        0 < a.y0 - a.height && a.y0 < parent_box.height
    end

    # Checking for label overlaps is O(n^2). To mitigate these costs, we build a
    # sparse overlap matrix. This also costs O(n^2), but we only have to do it
    # once, rather than every iteration of annealing.
    possible_overlaps = [Array(Int, 0) for _ in 1:length(positions)]

    # TODO: this whole thing would be much more effecient if we forbid from
    # the start labels that overlap points. We should be able to precompute
    # that, since they're static.

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

    label_visibility = fill(true, length(positions))

    num_iterations = n * theme.label_placement_iterations
    for k in 1:num_iterations
        if total_penalty == 0
            break
        end
        j = rand(1:n)

        new_total_penalty = total_penalty

        # Propose flipping the visibility of the label.
        if label_visibility[j] && geom.hide_overlaps && rand() < theme.label_visibility_flip_pr
            pos = nothing
            new_total_penalty += theme.label_hidden_penalty

        # Propose a change to label placement.
        else
            if !label_visibility[j]
                new_total_penalty -= theme.label_hidden_penalty
            end

            r = rand()
            point_x, point_y = point_positions[j]
            xspan = extents[j][1].abs
            yspan = extents[j][2].abs

            if rand() < 0.5
                xpos = Gadfly.lerp(rand(),
                                   (point_x - 7xspan/8),
                                   (point_x - 6xspan/8))
            else
                xpos = Gadfly.lerp(rand(),
                                   (point_x - 2xspan/8),
                                   (point_x - 1xspan/8))
            end

            ypos = Gadfly.lerp(rand(),
                               (point_y - 3yspan/4),
                               (point_y - 1yspan/4))

            # choose a side
            if r < 0.25 # top
                pos = AbsoluteBoundingBox(xpos, point_y - extents[j][2].abs,
                                          extents[j][1].abs, extents[j][2].abs)
            elseif 0.25 <= r < 0.5 # right
                pos = AbsoluteBoundingBox(point_x, ypos,
                                          extents[j][1].abs, extents[j][2].abs)
            elseif 0.5 <= r < 0.75 # bottom
                pos = AbsoluteBoundingBox(xpos, point_y,
                                          extents[j][1].abs, extents[j][2].abs)
            else # left
                pos = AbsoluteBoundingBox(point_x - extents[j][1].abs, ypos,
                                          extents[j][1].abs, extents[j][2].abs)
            end
        end

        if !box_contains(positions[j]) && label_visibility[j]
            new_total_penalty -= theme.label_out_of_bounds_penalty
        end

        if !box_contains(pos)
            new_total_penalty += theme.label_out_of_bounds_penalty
        end

        for i in possible_overlaps[j]
            if overlaps(positions[i], positions[j]) &&
                    label_visibility[i] && label_visibility[j]
                new_total_penalty -= 1
            end

            if overlaps(positions[i], pos) && label_visibility[i]
                new_total_penalty += 1
            end
        end

        improvement = total_penalty - new_total_penalty

        T = 0.1 * (1.0 - (k / (1 + num_iterations)))
        if improvement >= 0 || rand() < exp(improvement / T)
            if pos === nothing
                label_visibility[j] = false
            else
                label_visibility[j] = true
                positions[j] = pos
            end
            total_penalty = new_total_penalty
        end

    end

    return compose!(
        context(),
        text([(positions[i].x0 + extents[i][1].abs/2)*mm for i in 1:n],
             [(positions[i].y0 + extents[i][2].abs/2)*mm for i in 1:n],
             aes.label,
             [hcenter], [vcenter]),
        visible(label_visibility),
        font(theme.point_label_font),
        fontsize(theme.point_label_font_size),
        fill(theme.point_label_color),
        stroke(nothing),
        svgclass("geometry"))
end


function render(geom::LabelGeometry, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, scales::Dict{Symbol, ScaleElement})
    Gadfly.assert_aesthetics_defined("Geom.Label", aes, :label, :x, :y)
    return ctxpromise(drawctx -> deferred_label_context(geom, aes, theme, drawctx))
end



