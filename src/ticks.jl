

# Find the smallest order of magnitude that is larger than xspan This is a
# little opaque because I want to avoid assuming the log function is defined
# over typeof(xspan)
function bounding_order_of_magnitude(xspan)
    DT = typeof(xspan)
    one_dt = one(DT)

    a = 1
    step = 1
    while xspan < 10.0^a * one_dt
        a -= step
    end

    b = 1
    step = 1
    while xspan > 10.0^b * one_dt
        b += step
    end

    while a + 1 < b
        c = div(a + b, 2)
        if xspan < 10.0^c * one_dt
            b = c
        else
            a = c
        end
    end

    return b
end


# Empty catchall
optimize_ticks() = {}


# Find some reasonable values for tick marks.
#
# This is basically Wilkinson's ad-hoc scoring method that tries to balance
# tight fit around the data, optimal number of ticks, and simple numbers.
#
# Args:
#   x_min: minimum value occuring in the data.
#   x_max: maximum value occuring in the data.
#   Q: tick intervals and scores
#   k_min: minimum number of ticks
#   k_max: maximum number of ticks
#   k_ideal: ideal number of ticks
#   strict_span: true if no ticks should be outside [x_min, x_max].
#
# Returns:
#   A Float64 vector containing tick marks.
#
function optimize_ticks{T}(x_min::T, x_max::T; extend_ticks::Bool=false,
                           Q=[(1.0,1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)],
                           k_min=2, k_max=10, k_ideal=5,
                           strict_span=false)

    Qv = [(float64(q[1]), float64(q[2])) for q in Q]
    optimize_ticks_typed(x_min, x_max, extend_ticks, Qv, k_min, k_max, k_ideal, strict_span)
end

function optimize_ticks_typed{T}(x_min::T, x_max::T, extend_ticks, Q::Vector{(Float64,Float64)}, k_min,
                           k_max, k_ideal, strict_span)
    one_t = one(T)
    if x_min == x_max
        R = typeof(1.0 * one_t)
        return R[x_min], x_min - one_t, x_min + one_t
    end

    const n = length(Q)

    # generalizing "order of magnitude"
    xspan = x_max - x_min
    z = bounding_order_of_magnitude(xspan)

    high_score = -Inf
    z_best = 0.0
    k_best = 0.0
    r_best = 0.0
    q_best = 0.0

    while k_max * 10.0^(z+1) * one_t > xspan
        for k in k_min:k_max
            for (q, qscore) in Q
                span = (k - 1) * q * 10.0^z * one_t
                if span < xspan
                    continue
                end

                r = ceil((x_max - span) / (q*10.0^z * one_t))
                while r*q*10.0^z * one_t <= x_min
                    has_zero = r <= 0 && abs(r) < k

                    # simplicity
                    s = has_zero ? 1.0 : 0.0

                    # granularity
                    g = 0 < k < 2k_ideal ? 1 - abs(k - k_ideal) / k_ideal : 0.0

                    # coverage
                    c = 1.5 * xspan/span

                    score = (1/4)g + (1/6)s + (1/3)c + (1/4)qscore

                    # strict limits on coverage
                    if strict_span && span > xspan
                        core -= 10000
                    elseif !strict_span && (span >= 2.0*xspan || span < xspan)
                        score -= 1000
                    end

                    if score > high_score
                        (q_best, r_best, k_best, z_best) = (q, r, k, z)
                        high_score = score
                    end
                    r += 1
                end
            end
        end
        z -= 1
    end

    span = q_best * 10.0^z_best * one_t
    if extend_ticks
        S = Array(typeof(1.0 * one_t), int(3 * k_best))
        for i in 0:(3*k_best - 1)
            S[i+1] = (r_best + i - k_best) * span
        end
        viewmin, viewmax = S[k_best + 1], S[2 * k_best]
    else
        S = Array(typeof(1.0 * one_t), int(k_best))
        for i in 0:(k_best - 1)
            S[i+1] = (r_best + i) * span
        end
        viewmin, viewmax = S[1], S[end]
    end

    S, viewmin, viewmax
end


function optimize_ticks(x_min::Date, x_max::Date; extend_ticks::Bool=false,
                        k_min=nothing, k_max=nothing,
                        scale=:auto)
    # This can be pretty simple. We are choosing ticks on one of three
    # scales: years, months, days.
    if year(x_max) - year(x_min) <= 1 && scale != :year
        if year(x_max) == year(x_min) && month(x_max) - month(x_min) <= 1 && scale != :month
            ticks = Date[]
            if x_max - x_min > days(7) && scale != :day
                # This will probably need to be smarter
                push!(ticks, x_min)
                while true
                    next_month = date(year(ticks[end]), month(ticks[end])) + month(1)
                    while ticks[end] + week(1) < next_month - days(2)
                        push!(ticks, ticks[end] + week(1))
                    end
                    push!(ticks, next_month)
                    if next_month >= x_max
                        break
                    end
                end
            else
                push!(ticks, x_min)
                while ticks[end] < x_max
                    push!(ticks, ticks[end] + day(1))
                end
            end

            viewmin, viewmax = ticks[1], ticks[end]
            ticks, viewmin, viewmax
        else
            ticks = Date[]
            push!(ticks, date(year(x_min), month(x_min)))
            while ticks[end] < x_max
                push!(ticks, ticks[end] + month(1))
            end
            viewmin, viewmax = ticks[1], ticks[end]

            ticks, x_min, x_max
        end
    else
        ticks, viewmin, viewmax =
            optimize_ticks(year(x_min), year(x_max), extend_ticks=extend_ticks)
        Date[date(y) for y in ticks], date(viewmin), date(viewmax)
    end
end



# Generate ticks suitable for multiple scales.
function multilevel_ticks{T}(viewmin::T, viewmax::T;
                             scales=[0.5, 5.0, 10.0])

    ticks = Dict()
    for scale in scales
        ticks[scale] = optimize_ticks(viewmin, viewmax,
                                       k_min=2*scale,
                                       k_max=max(3, 10*scale),
                                       k_ideal=max(2, 15*scale))[1]
    end

    return ticks
end


function multilevel_ticks(viewmin::Date, viewmax::Date;
                          scales=[:year, :month, :day])
    span = viewmax - viewmin
    ticks = Dict()
    for scale in scales
        if scale == :year
            s = span / days(360)
        elseif scale == :month
            s = span / day(90)
        else
            s = span / day(1)
        end

        ticks[s/20] = optimize_ticks(viewmin, viewmax, scale=scale)[1]
    end

    return ticks
end


