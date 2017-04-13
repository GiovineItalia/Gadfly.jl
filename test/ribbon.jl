
using Gadfly, DataFrames

xs = 0:0.1:20

df = DataFrame(
    x=xs,
    y=cos.(xs),
    ymin=cos.(xs) .- 0.5,
    ymax=cos.(xs) .+ 0.5,
)

plot(df, x=:x, y=:y, ymin=:ymin, ymax=:ymax, Geom.line, Geom.ribbon)


