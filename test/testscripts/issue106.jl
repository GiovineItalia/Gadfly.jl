using Gadfly, DataFrames

set_default_plot_size(6inch, 3inch)

df = DataFrame(pb = rand(1:50, 50),
    t = rand(1:50, 50),
    h =[0.0 for i in 1:50])

plot(df, x = :pb, y = :t, color = :h, Geom.rectbin)
