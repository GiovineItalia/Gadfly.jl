
require("distributions.jl")

abstract Statistic


type IdentityStatistic <: Statistic
end

apply_statistic(stat::IdentityStatistic, aes::Aesthetics) = aes


type HistogramStatistic <: Statistic
end

const stat_histogram = HistogramStatistic()


# Compute the cross validation risk for a histogram.
#
# This method was taken from "All of Statistics", by Larry Wasserman, but was
# developed first in "Emperical Choice of Histograms and Kernel Density
# Estimators" by Mats Rudemo.
#
# Args:
#   xs: Data the histogram will represent, sorted in ascending order.
#   m: Number of bins.
#
# Returns:
#   A risk value that should be minimized.
#
function cross_val_risk(xs::Vector{Float64}, m::Int)
    (x_min, x_max) = (xs[1], xs[end])

    # bandwidth
    h = (x_max - x_min) / m

    # current bin's upper bound
    b = x_min + h

    i = 1
    n = length(xs)
    r = 0
    for j in 1:m
        p = 0
        while i < n && xs[i] <= b
            p += 1
            i += 1
        end

        p /= n
        r += p^2
        b += h
    end

    r *= (n + 1) / ((n - 1) * h)
    r = (2 / ((n - 1) * h)) - r
    r
end



# Estimate the optimal number of bins for a histogram by minimizing cross
# validation risk.
#
# Args:
#   xs: Data the histogram will represent, sorted in asceding order.
#
# Returns:
#   The optimal number of bins.
#
function choose_bin_count(xs::Vector{Float64})
    # Number of bins
    m = 50

    # Cross validation risk, which we want to minimize.
    r = cross_val_risk(xs, m)

    # Magnitude of proposal offsets
    d = Poisson(3)

    # Run a few rounds of stochastic hill-clibing to find a good number
    N = 200
    for _ in 1:N
        off = rand(d)
        m_proposed = randbit() == 1 ? m + off : max(1, m - off)
        r_proposed = cross_val_risk(xs, m_proposed)

        # accept/reject
        if r_proposed < r
            m = m_proposed
            r = r_proposed
            println((m, r))
        end
    end

    m
end


function apply_statistic(stat::HistogramStatistic, aes::Aesthetics)
    println("apply_statistic")

    aes = copy(aes)

    sorted_x = sort(aes.x)
    n = length(sorted_x)
    m = choose_bin_count(sorted_x)
    h = (sorted_x[end] - sorted_x[1]) / m

    aes.x = Array(Float64, m)
    aes.y = Array(Float64, m)

    # current bin's upper bound
    b = sorted_x[1] + h
    i = 1

    for j in 1:m
        p = 0
        while i < n && sorted_x[i] <= b
            p += 1
            i += 1
        end

        aes.x[j] = j * h
        aes.y[j] = p
        b += h
    end

    aes
end


