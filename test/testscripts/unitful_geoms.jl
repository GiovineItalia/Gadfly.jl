using Unitful, Gadfly, DataFrames

a = -9.81u"m/s^2"
t = (1:0.5:10)u"s"
v = a .* t
v2 = v .+ 2u"m/s"
h = 0.5 * a .* t.^2
df = DataFrame(time=t, velocity=v, position=h,
               unitlesst=ustrip.(t), unitlessv=ustrip.(v), unitlessh=ustrip.(h),
               position2=reverse(h))

# Test various geometries with Unitful
p1 = plot(df, x=:time, y=:velocity, Geom.bar)
p2 = plot(df, x=:time, y=:position, Geom.point,
          intercept=[-80u"m"], slope=[10u"m/s"], Geom.abline)
p3 = plot(df, x=:time, y=:velocity, Geom.line,
          yintercept=[-20u"m/s", -40u"m/s"], Geom.hline)
# Currently explicitly stated that it loess and lm require arrays of plain numbers
#p4 = plot(df, x=:time, y=:position, Geom.point,
#          Geom.smooth(method=:loess, smoothing=0.2))
p4 = plot(df, x=:position, y=:velocity, Geom.path)
p5 = plot(df, x=:time, y=:position, Geom.step,
          xintercept=[3u"s", 8u"s"], Geom.vline)
p6 = plot(df, layer(x=:time, y=:position, Geom.line),
          layer(x=:time, y=:position2, Geom.bar))
gridstack(reshape([p1,p2,p3,p4,p5,p6], (2,3)))
