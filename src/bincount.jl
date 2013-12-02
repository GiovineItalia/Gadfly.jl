
# Optimization of bin counts for histograms, heatmaps, hexbin plots, etc.
#
# I'm using the penalized maximum-likelihood method proposed in
#   Birge, L, and Rozenholc, Y. (2006) How many bins should be put in a regular
#   histogram?
#
# There has been quite a bit written on this problem, but there are a number of
# methods that all seem to give good results with little difference. Birge's
# method is simple (it's just AIC with an extra logarithmic term), has a decent
# theoretical justification, and is general enough to apply to multidimensional
# and non-regular bin selecetion problems. Though, the penalty they use was
# optimized for regular histograms, so may need to be tweaked.
#
# The Birge penalty is
#    penalty(D) = D - 1 + log(D)^2.5
# where D is the number of bins. The 2.5 constant was arrived at emperically by
# optimizing over samples from example density functions.
#

# Penalized log-likelihood function for a histogram with d regular bins.
#
# Args:
#   d: Number of bins in the histogram.
#   n: Number of sample (which should equal sum(bincounts[1:d])).
#   bincounts: An array giving the number occurrences in each bin.
#   binwidth: Width of each bin in the histogram.
#
# Returns:
#   Log-likelihood with Birge's penalty applied.
#
function bincount_pll(d::Int, n::Int, bincounts::Vector{Int}, binwidth::Float64)
    ll = 0
    for i in 1:d
        if bincounts[i] > 0
            ll += bincounts[i] * log(bincounts[i] / (n * binwidth))
        end
    end
    ll - (d - 1 + log(d)^2.5)
end


# Optimize the number of bins for a regular one dimensional histogram.
#
# Args:
#   xs: A sample.
#
# Returns:
#   A tuple of the form (d, bincounts), where d gives the optimal number of
#   bins, and bincounts is an array giving the number of occurances in each bin.
#
function choose_bin_count_1d(xs::AbstractVector, min_bin_count=1, max_bin_count=150)
    n = length(xs)
    if n <= 1
        return 1, Int[0]
    end

    x_min, x_max = minimum(xs), maximum(xs)
    span = x_max - x_min

    d_min = min_bin_count
    d_max = max_bin_count
    bincounts = zeros(Int, d_max)

    d_best = d_min
    pll_best = -Inf

    # Brute force optimization: since the number of bins has to be reasonably
    # small to plot, this is pretty quick and very simple.
    for d in d_min:d_max
        binwidth = span / d
        bincounts[1:d] = 0

        for x in xs
            if !isconcrete(x)
                continue
            end
            bincounts[max(1, min(d, int(ceil((x - x_min) / binwidth))))] += 1
        end

        pll = bincount_pll(d, n, bincounts, binwidth)

        if pll > pll_best
            d_best = d
            pll_best = pll
        end
    end

    bincounts[1:d_best] = 0
    binwidth = span / d_best
    for x in xs
        if !isconcrete(x)
            continue
        end
        bincounts[max(1, min(d_best, int(ceil((x - x_min) / binwidth))))] += 1
    end

    (d_best, bincounts)
end


# Optimize the number of bins for regular two dimensional histograms.
#
# Args:
#   xs: Dimension one data.
#   ys: Dimension two data.
#
# Returns:
#   A tuple of the form (dx, dy, bincounts), where dx, dy gives the number of
#   bins in each respective dimension and bincounts is a dx by dy matrix giving
#   the count in each bin.
#
function choose_bin_count_2d(xs::AbstractVector, ys::AbstractVector,
                             xminbincount::Int, xmaxbincount::Int,
                             yminbincount::Int, ymaxbincount::Int)

    # For two demensions, I'm just going to optimize the marginal bin counts.
    # This might not be optimal, but its simple and fast.

    x_min, x_max = minimum(xs), maximum(xs)
    y_min, y_max = minimum(ys), maximum(ys)

    dx, _ = choose_bin_count_1d(xs, xminbincount, xmaxbincount)
    dy, _ = choose_bin_count_1d(ys, yminbincount, ymaxbincount)

    # bin widths
    wx = (x_max - x_min) / dx
    wy = (y_max - y_min) / dy

    bincounts = zeros(Int, (dy, dx))
    for (x, y) in zip(xs, ys)
        i = max(1, min(dx, int(ceil((x - x_min) / wx))))
        j = max(1, min(dy, int(ceil((y - y_min) / wy))))
        bincounts[j, i] += 1
    end

    (dy, dx, bincounts)
end




