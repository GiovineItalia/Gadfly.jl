using Gadfly, RDatasets, Dates

day = collect(Date("1960-01-01"):Dates.Day(1):Date("1999-12-31"))
t = Dates.value.(day)
w = 2π/365.25
D1 = DataFrame(Day=day, y=2*rand(length(day)) .* (1 .+ sin.(w*t)))
hline = Geom.hline(color="red")
plot(D1, x=:Day, y=:y, yintercept=[3.9], Geom.line, hline)
