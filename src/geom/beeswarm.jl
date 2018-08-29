struct BeeswarmGeometry <: Gadfly.GeometryElement
    # :vertical or :horizontal
    orientation::Symbol
    padding::Measure
    tag::Symbol
end
BeeswarmGeometry(; orientation=:vertical, padding=0.1mm, tag=empty_tag) =
        BeeswarmGeometry(orientation, padding, tag)

"""
    Geom.beeswarm[; (orientation=:vertical, padding=0.1mm)]

Plot the `x` and `y` aesthetics, the former being categorical and the latter
continuous, by shifting the x position of each point to ensure that there is at
least `padding` gap between neighbors.  If `orientation` is `:horizontal`,
switch x for y.  Points can optionally be colored using the `color` aesthetic.
"""
const beeswarm = BeeswarmGeometry

element_aesthetics(geom::BeeswarmGeometry) = [:x, :y, :color]

function render(geom::BeeswarmGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.point", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes,
                                          element_aesthetics(geom)...)
    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGBA{Float32}[theme.default_color])
    default_aes.size = Measure[theme.point_size]
    aes = inherit(aes, default_aes)

    ctxp = ctxpromise() do draw_context
        if geom.orientation == :horizontal
            valvar = :x
            grpvar = :y
            cu = cy
        else
            valvar = :y
            grpvar = :x
            cu = cx
        end

        val = getfield(aes, valvar)
        grp = getfield(aes, grpvar)

        p = sortperm(val)
        permute!(val, p)
        permute!(grp, p)
        if length(aes.color) > 1
            permute!(aes.color, p)
        end

        point_dist = (2*theme.point_size + geom.padding).value
        point_dist += eps(point_dist)
        offsets = Array{Length{:mm}}(undef, length(val))
        positions = Array{Compose.Measure}(undef, length(val))

        n = length(val)
        overlaps = Array{Bool}(undef, n)
        absvals = Array{Float64}(undef, n)
        for (i, v) in enumerate(val)
            absvals[i] = Compose.resolve_position(
                    draw_context.box,
                    draw_context.units,
                    draw_context.t,
                    geom.orientation == :horizontal ? v * cx : v * cy).value
        end

        for (i, gi) in enumerate(takestrict(cycle(grp), n))
            off = 0mm

            hasoverlap = false
            firstoverlap = 0
            for (j, gj) in zip(1:(i-1), cycle(grp))
                overlaps[j] = false
                if gi == gj
                    gap = abs(absvals[i] - absvals[j])
                    if gap < point_dist
                        overlaps[j] = true
                        hasoverlap = true
                        if firstoverlap == 0
                            firstoverlap = j
                        end
                    end
                end
            end

            if hasoverlap
                # try 0 offset
                has_zero_overlap = false
                for j in firstoverlap:(i-1)
                    if !overlaps[j] continue end
                    if sqrt((absvals[i] - absvals[j])^2 + offsets[j].value^2) < point_dist
                        has_zero_overlap = true
                        break
                    end
                end

                if !has_zero_overlap
                    @goto offset_found
                end

                # try candidate offsets
                best_candidate = Inf
                for j in firstoverlap:(i-1)
                    if !overlaps[j] continue end
                    d = sqrt(point_dist^2 - (absvals[i] - absvals[j])^2)

                    for s in [1, -1]
                        candidate_off = offsets[j].value + s * d
                        candidate_has_overlap = false
                        for k in firstoverlap:(i-1)
                            if !overlaps[k] continue end

                            if sqrt((candidate_off - offsets[k].value)^2 +
                                    (absvals[i] - absvals[k])^2) < point_dist
                                candidate_has_overlap = true
                                break
                            end
                        end
                        if !candidate_has_overlap && abs(candidate_off) < abs(best_candidate)
                            best_candidate = candidate_off
                        end
                    end
                end

                if !isfinite(best_candidate)
                    off = 0mm
                else
                    off = best_candidate * mm
                end
            end

            @label offset_found
            offsets[i] = off
            positions[i] = gi * cu + off
        end

        if geom.orientation == :horizontal
            f = Shape.circle(val, positions, aes.size, geom.tag)
        else
            f = Shape.circle(positions, val, aes.size, geom.tag)
        end

        return compose(context(), f, fill(aes.color), svgclass("marker"),
                       linewidth(theme.highlight_width), stroke(nothing))
    end

    return compose!(context(order=4), svgclass("geometry"), ctxp)
end
