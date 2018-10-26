###  only single scale in SVG[^JS]

struct LabelGeometry <: Gadfly.GeometryElement
    # One of :dynamic, :left, :right, :above, :below, :centered
    position::Symbol

    # If true, hide labels that can't be made to not-overlap during dynamic
    # label layout.
    hide_overlaps::Bool

    tag::Symbol
end
LabelGeometry(; position=:dynamic, hide_overlaps=true, tag=empty_tag) = 
        LabelGeometry(position, hide_overlaps, tag)

element_aesthetics(::LabelGeometry) = [:x, :y, :label]

default_statistic(::LabelGeometry) = Gadfly.Stat.identity()

"""
    Geom.label[(; position=:dynamic, hide_overlaps=true)]

Place the text strings in the `label` aesthetic at the `x` and `y` coordinates
on the plot frame.  Offset the text according to `position`, which can be
`:left`, `:right`, `:above`, `:below`, `:centered`, or `:dynamic`.  The latter
tries a variety of positions for each label to minimize the number that overlap.
"""
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

    num_labels = length(aes.label)

    if aes.size == nothing
        padding = fill(theme.point_size, num_labels) .+ theme.label_padding
    else
        padding = aes.size .+ theme.label_padding
    end

    point_positions = Array{AbsoluteVec2}(undef, 0)
    for (x, y) in zip(aes.x, aes.y)
        x = Compose.resolve_position(parent_box, units, parent_transform, Compose.x_measure(x))
        y = Compose.resolve_position(parent_box, units, parent_transform, Compose.y_measure(y))
        push!(point_positions, (x, y))
    end

    label_extents = text_extents(theme.point_label_font, theme.point_label_font_size, aes.label...)

    # the first n values in label_point_{boxes,extents} correspond to the labels
    label_point_boxes = Absolute2DBox[]
    label_point_extents = AbsoluteVec2[]
    for (point_position, pad, (text_width, text_height)) in
            zip(point_positions, padding, label_extents)
        push!(label_point_boxes, Absolute2DBox(
                (point_position[1]-text_width/8, point_position[2]+pad),
                (text_width, text_height)))
        push!(label_point_extents, AbsoluteVec2((text_width, text_height)))
    end

    # the second n values in label_point_{boxes,extents} correspond to the points
    for ((x,y),pad) in zip(point_positions, padding)
        push!(label_point_boxes, Absolute2DBox((x-pad, y-pad), (2pad,2pad)))
        push!(label_point_extents, (2pad,2pad))
    end

    "Return a box containing every point that label `i` could possibly overlap."
    max_extents(i) = Absolute2DBox(
            (point_positions[i][1] - padding[i] - label_point_extents[i][1],
             point_positions[i][2] - padding[i] - label_point_extents[i][2]),
            (2*(padding[i] + label_point_extents[i][1]),
             2*(padding[i] + label_point_extents[i][2])))

    "Returns `true` if boxes `a` and `b` overlap."
    function overlaps(a::Absolute2DBox, b::Absolute2DBox)
        a.x0[1] + a.a[1] >= b.x0[1] && a.x0[1] <= b.x0[1] + b.a[1] &&
        a.x0[2] + a.a[2] >= b.x0[2] && a.x0[2] <= b.x0[2] + b.a[2]
    end

    # Checking for label overlaps is O(n^2). To mitigate these costs, we build a
    # sparse overlap matrix. This also costs O(n^2), but we only have to do it
    # once, rather than every iteration of annealing.
    possible_overlaps = [Array{Int}(undef, 0) for _ in 1:length(label_point_boxes)]

    # TODO: this whole thing would be much more effecient if we forbid from
    # the start labels that overlap points. We should be able to precompute
    # that, since they're static.

    for j in 1:num_labels
        for i in (j+1):num_labels  # automatically skips i==j
            if overlaps(max_extents(i), max_extents(j))
                push!(possible_overlaps[i], j)
                push!(possible_overlaps[j], i)
            end
        end

        for i in (num_labels+1):2*num_labels
            # skip the point box corresponding to label
            i==j+num_labels && continue

            if overlaps(label_point_boxes[i], max_extents(j))
                push!(possible_overlaps[i], j)
                push!(possible_overlaps[j], i)
            end
        end
    end

    "Returns `true` if `a` is fully contained in plot window."
    plot_contains(a::Absolute2DBox) =
            0mm < a.x0[1] && a.x0[1] + a.a[1] < parent_box.a[1] &&
            0mm < a.x0[2] && a.x0[2] + a.a[2] < parent_box.a[2]

    # This variable holds the value of the objective function we wish to
    # minimize. A label overlap is a penalty of 1. Other penaties (out of bounds
    # labels, hidden labels) or calibrated to that.
    total_penalty = 0.0

    for i in 1:num_labels
        if !plot_contains(label_point_boxes[i])
            total_penalty += theme.label_out_of_bounds_penalty
        end
    end

    for j in 1:num_labels
        for i in possible_overlaps[j]
            if i > j && overlaps(label_point_boxes[i], label_point_boxes[j])
                total_penalty += 1
            end
        end
    end

    label_visibility = fill(true, length(label_point_boxes))

    num_iterations = num_labels * theme.label_placement_iterations
    for k in 1:num_iterations
        total_penalty==0 && break

        j = rand(1:num_labels)

        new_total_penalty = total_penalty
        candidate_box = BoundingBox(0mm, 0mm, 0mm, 0mm)
        propose_hide = false

        # Propose flipping the visibility of the label.
        if geom.hide_overlaps && label_visibility[j] && rand() < theme.label_visibility_flip_pr
            propose_hide = true
            new_total_penalty += theme.label_hidden_penalty

        # Propose a change to label placement.
        else
            if !label_visibility[j]
                new_total_penalty -= theme.label_hidden_penalty
            end

            r = rand()
            point_x, point_y = point_positions[j]
            xspan = label_point_extents[j][1]
            yspan = label_point_extents[j][2]

            # TODO: it doesn't know what xspan, yspan are. That's the major
            # source of slowness.
            if rand() < 0.5
                xpos = Gadfly.lerp(rand(), (point_x - 7xspan/8), (point_x - 6xspan/8))
            else
                xpos = Gadfly.lerp(rand(), (point_x - 2xspan/8), (point_x - 1xspan/8))
            end

            ypos = Gadfly.lerp(rand(), (point_y - 3yspan/4), (point_y - 1yspan/4))

            # choose a side
            if r < 0.25 # above
                candidate_box = Absolute2DBox(
                        (xpos, point_y - label_point_extents[j][2] - padding[j]),
                        (label_point_extents[j][1], label_point_extents[j][2]))
            elseif 0.25 <= r < 0.5 # right
                candidate_box = Absolute2DBox(
                        (point_x + padding[j], ypos),
                        (label_point_extents[j][1], label_point_extents[j][2]))
            elseif 0.5 <= r < 0.75 # below
                candidate_box = Absolute2DBox(
                        (xpos, point_y + padding[j]),
                        (label_point_extents[j][1], label_point_extents[j][2]))
            else # left
                candidate_box = Absolute2DBox(
                        (point_x - label_point_extents[j][1] - padding[j], ypos),
                        (label_point_extents[j][1], label_point_extents[j][2]))
            end
        end

        if !plot_contains(label_point_boxes[j]) && label_visibility[j]
            new_total_penalty -= theme.label_out_of_bounds_penalty
        end

        if !propose_hide && !plot_contains(candidate_box)
            new_total_penalty += theme.label_out_of_bounds_penalty
        end

        for i in possible_overlaps[j]
            if label_visibility[i] && label_visibility[j] &&
                        overlaps(label_point_boxes[i], label_point_boxes[j])
                new_total_penalty -= 1
            end

            if label_visibility[i] && overlaps(label_point_boxes[i], candidate_box)
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
                label_point_boxes[j] = candidate_box
            end
            total_penalty = new_total_penalty
        end
    end

    return compose!(context(),
        (context(), text([point_positions[i][1] for i in 1:num_labels],
             [point_positions[i][2] for i in 1:num_labels],
             aes.label,
             [hcenter], [vcenter], [Rotation()],
             [(label_point_boxes[i].x0[1] - point_positions[i][1] + label_point_extents[i][1]/2,
               label_point_boxes[i].x0[2] - point_positions[i][2] + label_point_extents[i][2]/2)
              for i in 1:num_labels],
             tag=geom.tag), svgclass("marker")),
        visible(label_visibility),
        font(theme.point_label_font),
        fontsize(theme.point_label_font_size),
        fill(theme.point_label_color),
        stroke(nothing),
        svgclass("geometry"))
end


const label_layouts = Dict(
    :left     => (hright,  vcenter, -1,  0),
    :right    => (hleft,   vcenter,  1,  0),
    :above    => (hcenter, vbottom,  0, -1),
    :below    => (hcenter, vtop,     0,  1),
    :centered => (hcenter, vcenter,  0,  0)
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
        if aes.size == nothing
            offsets = [(xoff*(theme.point_size + theme.label_padding),
                        yoff*(theme.point_size + theme.label_padding))]
        else
            offsets = [(xoff*(point_size+theme.label_padding),
                        yoff*(point_size+theme.label_padding)) for point_size in aes.size]
        end

        return compose!(context(),
            (context(), text([Compose.x_measure(x) for x in aes.x],
                 [Compose.y_measure(y) for y in aes.y],
                 aes.label,
                 [hpos], [vpos], [Rotation()], offsets, tag=geom.tag),
                 svgclass("marker")),
            font(theme.point_label_font),
            fontsize(theme.point_label_font_size),
            fill(theme.point_label_color),
            stroke(nothing),
            svgclass("geometry"))
    end
end
