using Gadfly, DataFrames, Dates

set_default_plot_size(6inch, 3inch)

a = collect(Date("2013-01-01"):Day(1):Date("2014-01-01"))
b = collect(Date("2012-01-01"):Day(1):Date("2016-01-01"))
ya = sin.(0.01 * Float64.(Dates.value.(a)))
yb = cos.(0.01 * Float64.(Dates.value.(b)))

df1 = DataFrame(
    x = a,
    y = ya,
    label = "first"
)

df2 = DataFrame(
    x = b,
    y = yb,
    label = "second"
)

df = vcat(df1, df2)

plot(df, x = :x, y = :y, color=:label, Geom.line)
