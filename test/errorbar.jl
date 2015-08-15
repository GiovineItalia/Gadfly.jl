
using Gadfly
using RDatasets
using Distributions

sds = [1, 1/2, 1/4, 1/8, 1/16, 1/32]
n = 10
ys = [mean(rand(Normal(0, sd), n)) for sd in sds]
ymins = ys .- (1.96 * sds / sqrt(n))
ymaxs = ys .+ (1.96 * sds / sqrt(n))
cs = [string(i) for i in 1:length(sds)]

plot(x=1:length(sds),
    x=ys, xmin=ymins, xmax=ymaxs,
    y=ys, ymin=ymins, ymax=ymaxs, color=cs, Geom.point, Geom.errorbar)
