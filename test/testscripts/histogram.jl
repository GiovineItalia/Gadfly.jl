using RDatasets, Gadfly

set_default_plot_size(9inch, 9inch)

df1 = dataset("ggplot2", "diamonds")
df2 = dataset("car", "SLID")

# colorful_hist, histogram_density, histogram_explicit_bins
p1 = plot(df1, x=:Price, color=:Cut, Geom.histogram)
# p2: see issue #880
p2 = plot(df1, x=:Price, color=:Cut, Geom.histogram(bincount=30, density=true))
p3 = plot(df1, x=:Price, Geom.histogram(bincount=30))

# stacked_continuous_histogram, stacked_discrete_histogram, stacked_discrete_histogram_horizontal
p4 = plot(df2, x=:Wages, color=:Language, Geom.histogram)
p5 = plot(df2, x=:Wages, color=:Language, Geom.histogram(position=:stack))
p6 = plot(df2, color=:Language, y=:Wages, Geom.histogram(position=:stack, orientation=:horizontal))

# dodged_discrete_histogram, dodged_discrete_histogram_horizontal
p7 = plot(df2, x=:Wages, color=:Language, Geom.histogram(position=:dodge))
p8 = plot(df2, y=:Wages, color=:Language, Geom.histogram(position=:dodge, orientation=:horizontal))
p9 = plot()


gridstack([p1 p2 p3; p4 p5 p6; p7 p8 p9])
