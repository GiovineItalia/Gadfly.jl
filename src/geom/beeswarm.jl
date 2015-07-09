

immutable BeeswarmGeometry <: Gadfly.GeometryElement
    # :vertical or :horizontal
    orientation::Symbol
    padding::Measure

    function BeeswarmGeometry(; orientation::Symbol=:vertical, padding::Measure=0.1mm)
        new(orientation, padding)
    end
end


const beeswarm = BeeswarmGeometry


function element_aesthetics(geom::BeeswarmGeometry)
    [:x, :y, :color]
end


function render(geom::BeeswarmGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.point", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.point", aes,
                                          element_aesthetics(geom)...)
    default_aes = Gadfly.Aesthetics()
    default_aes.color = PooledDataArray(RGBA{Float32}[theme.default_color])
    default_aes.size = Measure[theme.default_point_size]
    aes = inherit(aes, default_aes)
    padding = 1.0mm

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

        point_dist = (2*theme.default_point_size + geom.padding).abs
        positions = Array(Compose.Measure, length(val))

        n = length(val)
        overlaps = Array(Bool, n)
        absvals = Array(Float64, n)
        for (i, v) in enumerate(val)
            if geom.orientation == :horizontal
                absvals[i] = Compose.absolute_x_position(v * cx, draw_context.t,
                                                         draw_context.units,
                                                         draw_context.box)
            else
                absvals[i] = Compose.absolute_y_position(v * cy, draw_context.t,
                                                         draw_context.units,
                                                         draw_context.box)
            end
        end

        for (i, gi) in enumerate(takestrict(cycle(grp), n))
            off = 0mm

            hasoverlap = false
            for (j, gj) in zip(1:(i-1), cycle(grp))
                overlaps[j] = false
                if gi == gj
                    gap = abs(absvals[i] - absvals[j])
                    if gap < point_dist
                        overlaps[j] = true
                        hasoverlap = true
                    end
                end
            end

            if hasoverlap
                # try 0 offset
                has_zero_overlap = false
                for j in 1:(i-1)
                    if !overlaps[j] continue end
                    if sqrt((absvals[i] - absvals[j])^2 + positions[j].abs^2) < point_dist
                        has_zero_overlap = true
                        break
                    end
                end

                if !has_zero_overlap
                    @goto offset_found
                end

                # try candidate offsets
                # TODO: This is O(n^2). We could probably do better in practice
                # by skipping the first 1:l points where l is the first point
                # that could intersect this one.
                best_candidate = Inf
                for j in 1:(i-1)
                    if !overlaps[j] continue end
                    d = sqrt(point_dist^2 - (absvals[i] - absvals[j])^2)

                    for s in [1, -1]
                        candidate_off = positions[j].abs + s * d
                        candidate_has_overlap = false
                        for k in 1:(i-1)
                            if !overlaps[k] continue end

                            if sqrt((candidate_off - positions[k].abs)^2 +
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
            positions[i] = gi * cu + off
        end

        if geom.orientation == :horizontal
            f = circle(val, positions, aes.size)
        else
            f = circle(positions, val, aes.size)
        end

        return compose(context(), f, fill(aes.color),
                       linewidth(theme.highlight_width), stroke(nothing))
    end

    return compose!(context(order=4), svgclass("geometry"), ctxp)
end





