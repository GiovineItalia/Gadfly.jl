using Unitful, Gadfly, DataFrames

a = -9.81u"m/s^2"
t = (1:0.5:10)u"s"
v = a .* t
v2 = v .+ 2u"m/s"
h = 0.5 * a .* t.^2
df = DataFrame(time=t, velocity=v, position=h,
               unitlesst=ustrip.(t), unitlessv=ustrip.(v), unitlessh=ustrip.(h),
               position2=reverse(h))

# test basics of point/line plots with Unitful
gridstack(reshape([plot(df, x=:time, y=:velocity),
                   plot(df, x=:position, y=:time),
                   plot(df, x=:unitlesst, y=:velocity),
                   plot(df, x=:time, y=:unitlessh),
                   plot(df, x=:time, y=:position, Geom.line),
                   plot(df, layer(x=:time, y=:position, Geom.line),
                        layer(x=:time, y=:position2))], (3,2)))
