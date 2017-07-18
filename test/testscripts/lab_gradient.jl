using Gadfly

set_default_plot_size(6inch, 3inch)

# Issue #678
x = repeat(collect(1:10), inner=[10])
y = repeat(collect(1:10), outer=[10])
plot(x=x,y=y,color=x+y, Geom.rectbin,
            Scale.ContinuousColorScale(Scale.lab_gradient(colorant"green",
                                                          colorant"white",
                                                          colorant"red")))
