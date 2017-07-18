using Gadfly, RDatasets

set_default_plot_size(6inch, 12inch)

p1 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Stat.binmean, Geom.point)
# color works
p2 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", color = "Species", Stat.binmean, Geom.point)
# n changes number of bins
p3 = plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", color="Species", Stat.binmean(n=3), Geom.point)
# integer works
p4 = plot(x= rand(1:10, 100), y = rand(1:10, 100), Stat.binmean, Geom.point)
#  surimpose regression
p5 = plot(
		layer(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", color="Species", Stat.binmean(n=5), Geom.point),
		layer(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", color="Species", Geom.smooth(method=:lm))
	)
vstack(p1, p2, p3, p4, p5)
