
immutable LabelGeometry <: Gadfly.GeometryElement
    # One of :dynamic, :left, :right, :above, :below, :centered
    position::Symbol

    # If true, hide labels that can't be made to not-overlap during dynamic
    # label layout.
    hide_overlaps::Bool

    tag::Symbol

    function LabelGeometry(;position=:dynamic, hide_overlaps::Bool=true, tag::Symbol=empty_tag)
        new(position, hide_overlaps, tag)
    end
end


element_aesthetics(::LabelGeometry) = [:x, :y, :label]


default_statistic(::LabelGeometry) = Gadfly.Stat.identity()


const label = LabelGeometry


# True if two boxes overlap
function overlaps(a::Absolute2DBox, b::Absolute2DBox)
    a.x0[1] + a.a[1] >= b.x0[1] && a.x0[1] <= b.x0[1] + b.a[1] &&
    a.x0[2] + a.a[2] >= b.x0[2] && a.x0[2] <= b.x0[2] + b.a[2]
end


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

    canvas_width, canvas_height = parent_box.a[1], parent_box.a[2]

    # This should maybe go in theme? Or should we be using Aesthetics.size?
    padding = 2mm

    point_positions = Array(AbsoluteVec2, 0)
    for (x, y) in zip(aes.x, aes.y)
        x = Compose.resolve_position(parent_box, units, parent_transform, Compose.x_measure(x))
        y = Compose.resolve_position(parent_box, units, parent_transform, Compose.y_measure(y))
        x -= parent_box.x0[1]
        y -= parent_box.x0[2]
        push!(point_positions, (x, y))
    end

    extents = text_extents(theme.point_label_font,
                           theme.point_label_font_size,
                           aes.label...)
    extents = AbsoluteVec2[(width + padding, height + padding)
                           for (width, height) in extents]

    positions = Absolute2DBox[]
    for (i, (text_width, text_height)) in enumerate(extents)
        x, y = point_positions[i]
        push!(positions, Absolute2DBox((x, y), (text_width, text_height)))
    end

    # TODO: use Aesthetics.size and/or theme.default_point_size
    for (x, y) in point_positions
        push!(positions, Absolute2DBox((x - 0.5mm, y - 0.5mm), (1.0mm, 1.0mm)))
        push!(extents, (1mm, 1mm))
    end

    n = length(aes.label)

    # Return a box containing every point that the label could possibly overlap.
    function max_extents(i)
        Absolute2DBox((positions[i].x0[1] - extents[i][1],
                       positions[i].x0[2] - extents[i][2]),
                       (2*extents[i][1], 2*extents[i][2]))
    end

    # True if a is fully contained in box.
    function box_contains(a::Absolute2DBox)
        0mm < a.x0[1] && a.x0[1] + a.a[1] < parent_box.a[1] &&
        0mm < a.x0[2] - a.a[2] && a.x0[2] < parent_box.a[2]
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
    total_penalty = 0.0

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
        pos = BoundingBox(0mm, 0mm, 0mm, 0mm)
        propose_hide = false

        # Propose flipping the visibility of the label.
        if label_visibility[j] && geom.hide_overlaps && rand() < theme.label_visibility_flip_pr
            new_total_penalty += theme.label_hidden_penalty

            propose_hide = true

        # Propose a change to label placement.
        else
            if !label_visibility[j]
                new_total_penalty -= theme.label_hidden_penalty
            end

            r = rand()
            point_x, point_y = point_positions[j]
            xspan = extents[j][1]
            yspan = extents[j][2]

            # TODO: it doesn't know what xspan, yspan are. That's the major
            # source of slowness.
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
                pos = Absolute2DBox((xpos, point_y - extents[j][2]),
                                    (extents[j][1], extents[j][2]))
            elseif 0.25 <= r < 0.5 # right
                pos = Absolute2DBox((point_x, ypos),
                                    (extents[j][1], extents[j][2]))
            elseif 0.5 <= r < 0.75 # bottom
                pos = Absolute2DBox((xpos, point_y),
                                    (extents[j][1], extents[j][2]))
            else # left
                pos = Absolute2DBox((point_x - extents[j][1], ypos),
                                    (extents[j][1], extents[j][2]))
            end
        end

        if !box_contains(positions[j]) && label_visibility[j]
            new_total_penalty -= theme.label_out_of_bounds_penalty
        end

        if !propose_hide && !box_contains(pos)
            new_total_penalty += theme.label_out_of_bounds_penalty
        end

        for i in possible_overlaps[j]
            if label_visibility[i] && label_visibility[j] &&
                overlaps(positions[i], positions[j])
                new_total_penalty -= 1
            end

            if  label_visibility[i] && overlaps(positions[i], pos)
                new_total_penalty += 1
            end
        end

        improvement = total_penalty - new_total_penalty

        T = 0.1 * (1.0 - (k / (1 + num_iterations)))
        if improvement >= 0 || rand() < exp(improvement / T)
            if propose_hide
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
        text([positions[i].x0[1] + extents[i][1]/2 + parent_box.x0[1] for i in 1:n],
             [positions[i].x0[2] + extents[i][2]/2 + parent_box.x0[2] for i in 1:n],
             aes.label,
             [hcenter], [vcenter]; tag=geom.tag),
        visible(label_visibility),
        font(theme.point_label_font),
        fontsize(theme.point_label_font_size),
        fill(theme.point_label_color),
        stroke(nothing),
        svgclass("geometry"))
end


const label_layouts = @compat Dict(
    :left     => (hright,  vcenter, -2mm,  0mm),
    :right    => (hleft,   vcenter,  2mm,  0mm),
    :above    => (hcenter, vbottom,  0mm, -2mm),
    :below    => (hcenter, vtop,     0mm,  2mm),
    :centered => (hcenter, vcenter,  0mm,  0mm)
)


function render(geom::LabelGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.Label", aes, :label, :x, :y)

    if geom.position == :dynamic
        return ctxpromise(drawctx -> deferred_label_context(geom, aes, theme, drawctx))
    else
        if !in(geom.position, [:left, :right, :above, :below, :centered])
            error("""
                The position argument of Geom.label must be one of :dynamic,
                :left, :right, :above, :below, :centered
                """)
        end

        hpos, vpos, xoff, yoff = label_layouts[geom.position]

        return compose!(
            context(),
            text([Compose.x_measure(x) + xoff for x in aes.x],
                 [Compose.y_measure(y) + yoff for y in aes.y],
                 aes.label,
                 [hpos], [vpos]; tag=geom.tag),
            font(theme.point_label_font),
            fontsize(theme.point_label_font_size),
            fill(theme.point_label_color),
            stroke(nothing),
            svgclass("geometry"))
    end
end
