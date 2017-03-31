
using Gadfly, RDatasets, Compose

plot(sin, 0, 25,
     xintercept=[0, pi, 2pi, 3pi],
     yintercept=[0, -1, 1],
     Geom.hline(style=[:dot,[1mm,1mm],:solid]), Geom.vline(style=:dashdot))

plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth",
   yintercept=[2.5, 4.0], Geom.point,
   Geom.hline(color=["orange","red"], size=[2mm,3mm]))

plot(dataset("ggplot2", "mpg"), x="Cty", y="Hwy", label="Model", Geom.point, Geom.label,
    yintercept=[0], xslope=[1], Geom.abline(color="red", style=:dash),
    Guide.annotation(compose(context(), text(6,4, "y=x", hleft, vtop), fill(colorant"red"))))

# issue 961
day = collect(Date("1960-01-01"):Dates.Day(1):Date("1999-12-31"))
t = Dates.value.(day)
w = 2π/365.25
D1 = DataFrame(Day=day, y=2*rand(length(day)).*(1+sin(w*t)))
hline = Geom.hline(color="red")
p = plot(D1, x=:Day, y=:y, yintercept=[3.9], Geom.line, hline )
