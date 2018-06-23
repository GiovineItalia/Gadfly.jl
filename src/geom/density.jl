struct DensityGeometry <: Gadfly.GeometryElement
    stat::Gadfly.StatisticElement
    order::Int
    tag::Symbol
end

function DensityGeometry(; n=256,
                           bandwidth=-Inf,
                           adjust=1.0,
                           kernel=Normal,
                           trim=false,
                           scale=:area,
                           position=:dodge,
                           orientation=:horizontal,
                           order=1,
                           tag=empty_tag)
    stat = Gadfly.Stat.DensityStatistic(n, bandwidth, adjust, kernel, trim,
                                        scale, position, orientation, false)
    DensityGeometry(stat, order, tag)
end

DensityGeometry(stat; order=1, tag=empty_tag) = DensityGeometry(stat, order, tag)

"""
   Geom.density(; bandwidth, adjust, kernel, trim, scale, position, orientation, order)

Draws a kernel density estimate. This is a cousin of [`Geom.histogram`](@ref)
that is especially useful when the datapoints originate from a underlying smooth
distribution. Unlike histograms, density estimates do not suffer from edge
effects from incorrect bin choices. Some caveats do apply:

1) Plot components do not necessarily correspond to the raw datapoints, but
   instead to the kernel density estimation of the underlying distribution
2) Density estimation improves as a function of the number of data points and
   can be misleadingly smooth when the number of datapoints is small.
3) Results can be sensitive to the choise of `kernel` and `bandwidth`

For horizontal histograms (default), `Geom.density` draws the kernel density
estimate of `x` optionally grouped by `color`. If the `orientation=:vertical`
flag is passed to the function, then densities will be computed along `y`. The
estimates are normalized by default to have areas equal to 1, but this can
changed by passing `scale=:count` to scale by the raw number of datapoints or
`scale=:peak` to scale by the max height of the estimate. Additionally, multiple
densities can be stacked using the `position=:stack` flag or the conditional
density estimate can be drawn using `position=:fill`. See
[`Stat.DensityStatistic`](@ref Gadfly.Stat.DensityStatistic) for details on
optional parameters that can control the `bandwidth`, `kernel`, etc used.

External links

* [Kernel Density Estimation on Wikipedia](https://en.wikipedia.org/wiki/Kernel_density_estimation)
"""
const density = DensityGeometry

element_aesthetics(::DensityGeometry) = Symbol[]
default_statistic(geom::DensityGeometry) = Gadfly.Stat.DensityStatistic(geom.stat)

function render(geom::DensityGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.density", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.density", aes, :x, :y)

    grouped_data = Gadfly.groupby(aes, [:color], :y)
    densities = Array{NTuple{2, Float64}}[]
    colors = []

    for (keys, belongs) in grouped_data
        xs = aes.x[belongs]
        ys = aes.y[belongs]

        push!(densities, [(x, y) for (x, y) in zip(xs, ys)])
        push!(colors, keys[1] != nothing ? keys[1] : theme.default_color)
    end

    ctx = context(order=geom.order)
    # TODO: This should be user controllable
    if geom.stat.position == :dodge
        compose!(ctx, Compose.polygon(densities, geom.tag), stroke(colors), fill(nothing))
    else
        compose!(ctx, Compose.polygon(densities, geom.tag), fill(colors))
    end

    compose!(ctx, svgclass("geometry"))
end

struct ViolinGeometry <: Gadfly.GeometryElement
    stat::Gadfly.StatisticElement
    order::Int
    tag::Symbol
end

function ViolinGeometry(; n=256,
                          bandwidth=-Inf,
                          adjust=1.0,
                          kernel=Normal,
                          trim=true,
                          scale=:area,
                          orientation=:vertical,
                          order=1,
                          tag=empty_tag)
    stat = Gadfly.Stat.DensityStatistic(n, bandwidth, adjust, kernel, trim,
                                        scale, :dodge, orientation, true)
    ViolinGeometry(stat, order, tag)
end

"""
    Geom.violin[(; bandwidth, adjust, kernel, trim, order)]

Draws a violin plot which is a combination of [`Geom.density`](@ref) and
[`Geom.boxplot`](@ref). This plot type is useful for comparing differences in
the distribution of quantitative data between categories, especially when the
data is non-normally distributed. See [`Geom.density`](@ref) for some caveats.

In the case of standard vertical violins, `Geom.violin` draws the density
estimate of `y` optionally grouped categorically by `x` and colored
with `color`.  See [`Stat.DensityStatistic`](@ref Gadfly.Stat.DensityStatistic)
for details on optional parameters that can control the `bandwidth`, `kernel`,
etc used.

```@example
using RDatasets, Gadfly

df = dataset("ggplot2", "diamonds")

p = plot(df, x=:Cut, y=:Carat, color=:Cut, Geom.violin())
draw(SVG("diamonds_violin1.svg", 10cm, 8cm), p) # hide
nothing # hide
```
![](diamonds_violin1.svg)
"""
const violin = ViolinGeometry

element_aesthetics(::ViolinGeometry) = []

default_statistic(geom::ViolinGeometry) = Gadfly.Stat.DensityStatistic(geom.stat)

function render(geom::ViolinGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    Gadfly.assert_aesthetics_defined("Geom.violin", aes, :y, :width)
    Gadfly.assert_aesthetics_equal_length("Geom.violin", aes, :y, :width)

    output_dims, groupon = Gadfly.Stat._find_output_dims(geom.stat)
    grouped_data = Gadfly.groupby(aes, groupon, output_dims[2])
    violins = Array{NTuple{2, Float64}}[]

    (aes.color == nothing) && (aes.color = fill(theme.default_color, length(aes.x)))
    colors = eltype(aes.color)[]
    color_opts = unique(aes.color)
    split = false
    # TODO: Add support for dodging violins (i.e. having more than two colors
    # per major category). Also splitting should not happen automatically, but
    # as a optional keyword to Geom.violin
    if length(keys(grouped_data)) > 2*length(unique(getfield(aes, output_dims[1])))
        error("Violin plots do not currently support having more than 2 colors per $(output_dims[1]) category")
    elseif length(color_opts) == 2
        split = true
    end

    for (keys, belongs) in grouped_data
        x, color = keys
        ys = getfield(aes, output_dims[2])[belongs]
        ws = aes.width[belongs]

        if split
            pos = findfirst(color_opts, color)
            if pos == 1
                push!(violins, [(x - w/2, y) for (y, w) in zip(ys, ws)])
            else
                push!(violins, reverse!([(x + w/2, y) for (y, w) in zip(ys, ws)]))
            end
            push!(colors, color)
        else
            push!(violins, vcat([(x - w/2, y) for (y, w) in zip(ys, ws)],
                                reverse!([(x + w/2, y) for (y, w) in zip(ys, ws)])))
            push!(colors, color != nothing ? color : theme.default_color)
        end
    end

    if geom.stat.orientation == :horizontal
        for violin in violins
            for i in 1:length(violin)
                violin[i] = reverse(violin[i])
            end
        end
    end

    ctx = context(order=geom.order)
    compose!(ctx, Compose.polygon(violins, geom.tag), fill(colors))

    compose!(ctx, svgclass("geometry"))

end
