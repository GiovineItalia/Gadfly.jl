using DataFrames, Gadfly, Dates

set_default_plot_size(6inch, 3inch)

# Geom.smooth already has tests for these types:
# Floats: smooth_lm.jl
# Ints: subplot_layers.jl

# This adds tests for Date and DateTime objects

t1 = Date("2001-01-15"):Dates.Month(1):Date("2016-12-31")
t2 = DateTime("2001-01-15"):Dates.Month(1):DateTime("2016-12-31")
t = Float64.(Dates.value.(t1))
n = length(t)
D = DataFrame(t1=t1, t2=t2, cycle = 5*sin.(t*2π/365.25)+randn(n), trend = 0.1*[1.0:n;].+2*randn(n))
Dl = melt(D,[:t1,:t2])

plot(D,
    x=:t1, y=:trend, Geom.point,
    Geom.smooth(method=:lm),
    Theme(point_size=1.8pt, key_position=:none)
    )

plot(Dl,
    x=:t2, y=:value, color=:variable, Geom.point,
    Geom.smooth(smoothing=0.05),
    Theme(point_size=1.8pt, key_position=:none)
    )
