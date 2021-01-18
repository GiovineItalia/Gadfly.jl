using Gadfly, DataFrames

set_default_plot_size(6.6inch, 6.6inch)

xs = 0:0.1:20

df = [DataFrame(x=xs, y=y, ymin=y.-0.5, ymax=y.+0.5, f=f) for (y,f) in zip((cos.(xs), sin.(xs)), ("cos", "sin"))]

p1 = plot(df[1], x=:x, y=:y, ymin=:ymin, ymax=:ymax, Geom.line, Geom.ribbon)
p2 = plot(df[1], Geom.ribbon, x=:x, ymin=:ymin, ymax=:ymax, color=[colorant"red"],  alpha=[0.3], Theme(lowlight_color=identity))
p3 = plot(df[1], Geom.ribbon, y=:x, xmin=:ymin, xmax=:ymax, color=[colorant"red"],  alpha=[0.3], Theme(lowlight_color=identity))
p4 = plot(vcat(df...), x=:x, y=:y, ymin=:ymin, ymax=:ymax, color=:f, Geom.line, Geom.ribbon)

gridstack([p1 p2; p3 p4])
