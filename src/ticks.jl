

# Find some reasonable values for tick marks.
#
# This is basically Wilkinson's ad-hoc scoring method that tries to balance
# tight fit around the data, optimal number of ticks, and simple numbers.
#
# Args:
#   x_min: minimum value occuring in the data.
#   x_max: maximum value occuring in the data.
#
# Returns:
#   A Float64 vector containing tick marks.
#
function optimize_ticks(x_min::Float64, x_max::Float64)
    if x_min == x_max
        return [x_min]
    end

    # TODO: these should perhaps be part of the theme
    const Q = {(1,1), (5, 0.9), (2, 0.7), (25, 0.5), (3, 0.2)}
    const n = length(Q)
    const k_min   = 2
    const k_max   = 10
    const k_ideal = 5

    xspan = x_max - x_min
    z = ceil(log10(xspan))

    high_score = -Inf
    z_best = 0.0
    k_best = 0.0
    r_best = 0.0
    q_best = 0.0

    while k_max * 10^(z+1) > xspan
        for k in k_min:k_max
            for (q, qscore) in Q
                span = (k - 1) * q * 10^z
                if span < xspan
                    continue
                end

                r = ceil((x_max - span) / (q*10^z))
                while r*q*10^z <= x_min
                    has_zero = r <= 0 && abs(r) < k

                    # simplicity
                    s = has_zero ? 1.0 : 0.0

                    # granularity
                    g = 0 < k < 2k_ideal ? 1 - abs(k - k_ideal) / k_ideal : 0.0

                    # coverage
                    c = 1.5 * xspan/span

                    score = (1/4)g + (1/6)s + (1/3)c + (1/4)qscore

                    # strict limits on coverage
                    if span >= 2*xspan || span < xspan
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

    S = Array(Float64, int(k_best))
    for i in 0:(k_best - 1)
        S[i+1] = (r_best + i) * q_best * 10^z_best
    end

    S
end

