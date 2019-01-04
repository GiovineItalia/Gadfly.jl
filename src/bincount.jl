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
function bincount_pll(d::Int, n::Int, bincounts::Vector{Int}, binwidth::AbstractFloat)
    ll = 0
    for i in 1:d
        if bincounts[i] > 0
            ll += bincounts[i] * log(d * bincounts[i] / (n * binwidth))
        end
    end

    ll - (d - 1 + log(d)^2.5)
end


# Estimate proportion of values that are distinct
#
# Sample enough values to decide whether we're effectively
# continuous (defined as >90% of the sampled values are unique)
# By looking at a subset we ensure this isn't a bottleneck
function estimate_distinct_proportion(values::AbstractArray{T}) where T
    uvalues = Set{T}()
    n_sampled = n_tried = 0
    while n_sampled < 15 && n_tried < length(values)
        v = values[rand(1:length(values))]
        n_tried += 1
        Gadfly.isconcrete(v) || continue
        n_sampled += 1
        push!(uvalues, v)
    end
    return length(uvalues) / n_sampled
end


# Tally elements in xs into an array of counts.
#
# Args:
#   bincounts: count per bin
#   xs: values being tallied
#   x_min: minimum value in xs
#   binwidth: width of each bin
#   numbins: number of bins
#
function bin!(bincounts::Vector, xs, x_min, binwidth, numbins)
    bincounts[1:numbins] .= 0
    for x in xs
        if !isconcrete(x)
            continue
        end
        idx = 1 + floor(Int, (x - x_min) / binwidth)
        bincounts[min(numbins, idx)] += 1
    end
end


# Optimize the number of bins for a regular one dimensional histogram.
#
# Args:
#   xs: A sample.
#   d_min: Minimum number of bins to consider.
#   d_max: Maximum number of bins to consider.
#
# Returns:
#   A tuple of the form (d, bincounts, x_max), where d gives the optimal number of
#   bins, and bincounts is an array giving the number of occurances in each
#   bin, and x_max is the end point of the final bin.
#
function choose_bin_count_1d(xs::AbstractVector, d_min=1, d_max=150)
    n = length(xs)
    if n == 0
        return 1, Int[0], 0
    elseif n == 1
        return 1, Int[1], xs[1]
    end

    x_min, x_max = Gadfly.concrete_minimum(xs), Gadfly.concrete_maximum(xs)
    span = x_max - x_min

    bincounts = zeros(Int, d_max)

    d_best = d_min
    pll_best = -Inf

    # Brute force optimization: since the number of bins has to be reasonably
    # small to plot, this is pretty quick and very simple.
    d_best = d_min
    if d_min < d_max
        for d in d_min:d_max
            binwidth = span / d
            bin!(bincounts, xs, x_min, binwidth, d)
            pll = bincount_pll(d, n, bincounts, binwidth)

            if pll > pll_best
                d_best = d
                pll_best = pll
            end
        end
    end

    binwidth = span / d_best
    bin!(bincounts, xs, x_min, binwidth, d_best)

    return d_best, bincounts, x_max
end


# Choose a reasonable number of bins when the data is considered discrete, which
# this case means integers, or low-resolution real number measurements.
#
# This works similarly to choose_bin_count_1d, except restricts the binwidths to
# be a multiple of the smallest distance between two adjacent unique values.
# E.g. for integer data, this means bin width are integers as well. This usually
# leads to better results.
#
# Args:
#   xs: A sample.
#   xs_set: An of the unique values in xs in sorted order.
#   d_min: Minimum number of allowed bins.
#   d_max: Maximum number of allowed bins.
#
# Returns
#   A tuple of the form (d, bincounts, x_max), where d gives the optimal number of
#   bins, and bincounts is an array giving the number of occurances in each
#   bin, and x_max is the end point of the final bin.
#
function choose_bin_count_1d_discrete(xs::AbstractArray, xs_set::AbstractArray,
                                      d_min=1, d_max=150)
    n = length(xs_set)
    T = eltype(xs)
    if n == 0
        return 1, Int[0], 0
    elseif n == 1
        return 1, Int[length(xs)], xs[1] + convert(T, one(T))
    end

    # minimum distance between two values
    T = eltype(xs)
    mingap = convert(T, zero(T))
    for (i, j) in zip(1:length(xs_set)-1, 2:length(xs_set))
        gap = xs_set[j] - xs_set[i]
        if isconcrete(gap) && gap > zero(T)
            if mingap == convert(T, zero(T))
                mingap = gap
            else
                mingap = min(gap, mingap)
            end
        end
    end

    x_min, x_max = Gadfly.concrete_minimum(xs), Gadfly.concrete_maximum(xs)
    span = x_max - x_min

    d_best = d_min
    pll_best = -Inf
    bincounts = zeros(Int, d_max)
    for d in d_min:d_max
        binwidth = span / d
        binwidth = ceil(binwidth / mingap) * mingap # round to a multiple of mingap

        # don't bother with binning that stretches past the end of the data
        if binwidth == mingap && x_min + binwidth * (d - 1) > x_max
            break
        end

        bin!(bincounts, xs, x_min, binwidth, d)
        pll = bincount_pll(d, n, bincounts, binwidth)

        if pll > pll_best
            d_best = d
            pll_best = pll
        end
    end

    d = d_best
    binwidth = ceil(span / d / mingap) * mingap
    x_max = x_min + binwidth * d
    bin!(bincounts, xs, x_min, binwidth, d_best)

    return d_best, bincounts, x_max
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

    x_min, x_max = Gadfly.concrete_minimum(xs), Gadfly.concrete_maximum(xs)
    y_min, y_max = Gadfly.concrete_minimum(ys), Gadfly.concrete_maximum(ys)

    if estimate_distinct_proportion(xs) < 0.9
        value_set = sort!(collect(Set(xs[Bool[Gadfly.isconcrete(v) for v in xs]])))
        dx, _ = choose_bin_count_1d_discrete(xs, value_set, xminbincount, xmaxbincount)
    else
        dx, _ = choose_bin_count_1d(xs, xminbincount, xmaxbincount)
    end

    if estimate_distinct_proportion(ys) < 0.9
        value_set = sort!(collect(Set(ys[Bool[Gadfly.isconcrete(v) for v in ys]])))
        dy, _ = choose_bin_count_1d_discrete(ys, value_set, yminbincount, ymaxbincount)
    else
        dy, _ = choose_bin_count_1d(ys, yminbincount, ymaxbincount)
    end

    # bin widths
    wx = (x_max==x_min) ? 1.0 : (x_max - x_min) / dx
    wy = (y_max==y_min) ? 1.0 : (y_max - y_min) / dy

    bincounts = zeros(Int, (dy, dx))
    for (x, y) in zip(xs, ys)
        if !Gadfly.isconcrete(x) || !Gadfly.isconcrete(y)
            continue
        end

        i = max(1, min(dx, 1 + (floor(Int, (x - x_min) / wx))))
        j = max(1, min(dy, 1 + (floor(Int, (y - y_min) / wy))))
        bincounts[j, i] += 1
    end

    (dy, dx, bincounts)
end


# Optimize the number of bins for hexagonal 2d histograms.
#
# Args:
#   xs: Dimension one data.
#   ys: Dimension two data.
#
# Returns:
#   A tuple of the form (size, bincounts), where 'size' is the hexagon size and
#   bincounts is an arrays storing the count for each hexagon, using axial
#   coordinates.
#
function choose_hex_bin_count(xs::AbstractVector, ys::AbstractVector)
    # TODO: this should probably be a thing
end
