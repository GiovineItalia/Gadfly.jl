using Gadfly

# wide-form plotting of heterogenous arrays of arrays

set_default_plot_size(4inch, 4inch)

xs = Any[Float32[0.547994, 0.819285, 0.567737, 0.557336, 0.27934, 0.777828, 0.8135, 0.00389743, 0.699683, 0.0958536],
         [0.951916, 0.999905, 0.251662, 0.986666, 0.555751, 0.437108, 0.424718, 0.773223, 0.28119, 0.209472, 0.251379, 0.0203749, 0.287702, 0.859512, 0.0769509],
         Float32[0.625995, 0.902331, 0.10869, 0.735902, 0.908017]]
plot(xs, x=Row.index, y=Col.value, color=Col.index, Scale.color_discrete, Geom.line)
