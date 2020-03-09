using Unitful, Gadfly, DataFrames

a = -9.81u"m/s^2"
t = (1:0.5:10)u"s"
v = a .* t
v2 = v .+ 2u"m/s"
h = 0.5 * a .* t.^2
df = DataFrame(time=t, velocity=v, position=h,
               unitlesst=ustrip.(t), unitlessv=ustrip.(v), unitlessh=ustrip.(h),
               position2=reverse(h))

# Test that it's possible to categorize by Unitful quantities
vstack(plot(df, x=:time, y=:position, color=:velocity, Geom.point),
       plot(df, x=:time, y=:velocity, color=:position, Geom.line),
       plot(df, x=:time, y=:position, color=:unitlessv))
