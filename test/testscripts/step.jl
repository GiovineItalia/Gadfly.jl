using Gadfly, DataFrames

set_default_plot_size(6inch, 3inch)

df = DataFrame(x=vcat(rand(10), rand(10)), y=rand(20),
               grouping=vcat(fill("A", 10), fill("B", 10)))
plot(df, x=:x, y=:y, color=:grouping, Geom.line, Stat.step)
