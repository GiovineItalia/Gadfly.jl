# Find the smallest order of magnitude that is larger than xspan This is a
# little opaque because I want to avoid assuming the log function is defined
# over typeof(xspan)
function bounding_order_of_magnitude(xspan::DT) where DT
    one_dt = oneunit(DT)

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
optimize_ticks() = Any[]


# Find some reasonable values for tick marks.
#
# This is basically Wilkinson's ad-hoc scoring method that tries to balance
# tight fit around the data, optimal number of ticks, and simple numbers.
#
# Args:
#   x_min: minimum value occurring in the data.
#   x_max: maximum value occurring in the data.
#   Q: tick intervals and scores
#   k_min: minimum number of ticks
#   k_max: maximum number of ticks
#   k_ideal: ideal number of ticks
#   strict_span: true if no ticks should be outside [x_min, x_max].
#
# Returns:
#   A Float64 vector containing tick marks.
#
function optimize_ticks(x_min::T, x_max::T; extend_ticks::Bool=false,
                        Q=[(1.0,1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)],
                        k_min::Int=2, k_max::Int=10, k_ideal::Int=5,
                        granularity_weight::Float64=1/4, simplicity_weight::Float64=1/6,
                        coverage_weight::Float64=1/3, niceness_weight::Float64=1/4,
                        strict_span=false) where T

    Qv = [((Float64(q[1])), (Float64(q[2]))) for q in Q]
    optimize_ticks_typed(x_min, x_max, extend_ticks, Qv, k_min, k_max, k_ideal,
                         granularity_weight, simplicity_weight,
                         coverage_weight, niceness_weight, strict_span)
end

function optimize_ticks_typed(x_min::T, x_max::T, extend_ticks,
                           Q::Vector{(Tuple{Float64,Float64})}, k_min,
                           k_max, k_ideal,
                           granularity_weight::Float64, simplicity_weight::Float64,
                           coverage_weight::Float64, niceness_weight::Float64,
                           strict_span) where T
    one_t = oneunit(T)
    if x_max - x_min < eps()*one_t
        R = typeof(1.0 * one_t)
        return R[x_min], x_min - one_t, x_min + one_t
    end

    n = length(Q)

    # generalizing "order of magnitude"
    xspan = x_max - x_min
    z = bounding_order_of_magnitude(xspan)

    high_score = -Inf
    z_best = 0.0
    k_best = 0
    r_best = 0.0
    q_best = 0.0

    while k_max * 10.0^(z+1) * one_t > xspan
        for k in k_min:k_max
            for (q, qscore) in Q
                span = (k - 1) * q * 10.0^z * one_t
                if span < xspan
                    continue
                end

                stp = q*10.0^z
                if stp < eps()
                    continue
                end
                r = ceil((x_max - span) / (stp * one_t))

                while r*stp * one_t <= x_min
                    has_zero = r <= 0 && abs(r) < k

                    # simplicity
                    s = has_zero ? 1.0 : 0.0

                    # granularity
                    g = 0 < k < 2k_ideal ? 1 - abs(k - k_ideal) / k_ideal : 0.0

                    # coverage
                    c = 1.5 * xspan/span

                    score = granularity_weight * g +
                            simplicity_weight * s +
                            coverage_weight * c +
                            niceness_weight * qscore

                    # strict limits on coverage
                    if strict_span && span > xspan
                        score -= 10000
                    elseif !strict_span && (span >= 2.0*xspan || span < xspan)
                        score -= 1000
                    end

                    if score > high_score
                        (q_best, r_best, k_best, z_best) = (q, r, k, z)
                        high_score = score
                    end

                    # Fix for #932
                    r += max(1, eps(r))
                end
            end
        end
        z -= 1
    end

    if isinf(high_score)
        R = typeof(1.0 * one_t)
        return R[x_min], x_min - one_t, x_min + one_t
    end

    span = q_best * 10.0^z_best * one_t
    if extend_ticks
        S = Array{typeof(1.0 * one_t)}(undef, Int(3 * k_best))
        for i in 0:(3*k_best - 1)
            S[i+1] = (r_best + i - k_best) * span
        end
        viewmin, viewmax = S[k_best + 1], S[2 * k_best]
    else
        S = Array{typeof(1.0 * one_t)}(undef, k_best)
        for i in 0:(k_best - 1)
            S[i+1] = (r_best + i) * span
        end
        viewmin, viewmax = S[1], S[end]
    end

    if strict_span
        viewmin = max(viewmin, x_min)
        viewmax = min(viewmax, x_max)
    end

    return S, viewmin, viewmax
end


function optimize_ticks(x_min::Date, x_max::Date;
                        extend_ticks::Bool=false,
                        k_min::Int=2, k_max::Int=10, k_ideal::Int=5,
                        granularity_weight::Float64=3/7, simplicity_weight=nothing,
                        coverage_weight::Float64=4/7, niceness_weight=nothing,
                        strict_span=false,
                        scales = [
                            Year(1), Quarter(1), Month(1), Week(1),
                            Day(1), Hour(1), Minute(1), Second(1), Millisecond(100),
                            Millisecond(10), Millisecond(1)])
    return optimize_ticks(convert(DateTime, x_min), convert(DateTime, x_max),
                          extend_ticks=extend_ticks,
                          k_min=k_min, k_max=k_max, k_ideal=k_ideal,
                          strict_span=strict_span,
                          scales=scales)
end


function optimize_ticks(x_min::DateTime, x_max::DateTime;
                        extend_ticks::Bool=false,
                        k_min::Int=2, k_max::Int=10, k_ideal::Int=5,
                        granularity_weight::Float64=3/7, simplicity_weight=nothing,
                        coverage_weight::Float64=4/7, niceness_weight=nothing,
                        strict_span=false,
                        scales = [
                            Year(1), Quarter(1), Month(1), Week(1),
                            Day(1), Hour(1), Minute(1), Second(1), Millisecond(100),
                            Millisecond(10), Millisecond(1)])

    x_min == x_max && (x_max += Second(1))
    xspan = x_max - x_min

    ticks, viewmin, viewmax =
        optimize_ticks(year(x_min), year(x_max + Year(1) - Day(1)),
                       extend_ticks=extend_ticks,
                       k_min=k_min, k_max=k_max, k_ideal=k_ideal,
                       strict_span=strict_span)
    ticks = sort(unique(round.(Int, ticks)))

    # granularity
    k = length(ticks)
    g = 1 - abs(k - k_ideal) / k_ideal

    # coverage
    c = 1.5 * xspan / (Date(maximum(ticks)) - Date(minimum(ticks)))

    score = granularity_weight * g + coverage_weight * c

    high_score = score
    ticks_best = DateTime[DateTime(y) for y in ticks]
    viewmin_best, viewmax_best = DateTime(round(viewmin)), DateTime(round(viewmax))

    last_score = -Inf
    for scale in scales
        ticks = DateTime[]

        if scale === Year(1)
            first_tick = DateTime(year(x_min))
        elseif scale === Quarter(1)
            first_tick = DateTime(year(x_min)) + Quarter(1)*(Dates.quarter(x_min)-1)
        elseif scale === Month(1)
            first_tick = DateTime(year(x_min), month(x_min))
        elseif scale === Week(1)
            first_tick = DateTime(year(x_min)) + Week(1)*(week(x_min)-1)
        elseif scale === Day(1)
            first_tick = DateTime(year(x_min), month(x_min), day(x_min))
        elseif scale === Hour(1)
            first_tick = DateTime(year(x_min), month(x_min), day(x_min),
                                  hour(x_min))
        elseif scale === Minute(1)
            first_tick = DateTime(year(x_min), month(x_min), day(x_min),
                                  hour(x_min), minute(x_min))
        elseif scale === Second(1)
            first_tick = DateTime(year(x_min), month(x_min), day(x_min),
                                  hour(x_min), minute(x_min), second(x_min))
        elseif scale === Millisecond(100)
            first_tick = DateTime(year(x_min), month(x_min), day(x_min),
                                  hour(x_min), minute(x_min),
                                  second(x_min), millisecond(x_min) % 100)
        elseif scale === Millisecond(10)
            first_tick = DateTime(year(x_min), month(x_min), day(x_min),
                                  hour(x_min), minute(x_min),
                                  second(x_min), millisecond(x_min) % 10)
        else
            first_tick = x_min
        end
        push!(ticks, first_tick)

        while ticks[end] < x_max
            push!(ticks, ticks[end] + scale)
        end

        # granularity
        k = length(ticks)
        g = 1 - abs(k - k_ideal) / k_ideal

        # coverage
        c = 1.5 * xspan / (maximum(ticks) - minimum(ticks))

        score = granularity_weight * g + coverage_weight * c

        if score > high_score
            ticks_best = ticks
            viewmin_best, viewmax_best = ticks[1], ticks[end]
            high_score = score
        end
        if score >= last_score
            last_score = score
        else
            break
        end
    end

    if strict_span
        viewmin_best = max(viewmin_best, x_min)
        viewmax_best = min(viewmax_best, x_max)
    end

    return ticks_best, viewmin_best, viewmax_best
end


# Generate ticks suitable for multiple scales.
function multilevel_ticks(viewmin::T, viewmax::T;
                          scales=[0.5, 5.0, 50.0]) where T

    ticks = Dict()
    for scale in scales
        ticks[scale] = optimize_ticks(viewmin, viewmax,
                                      k_min=max(1, (round(Int, 2*scale))),
                                      k_max=max(3, (round(Int, 10*scale))),
                                      k_ideal=max(2, (round(Int, 5*scale))))[1]
    end

    return ticks
end
