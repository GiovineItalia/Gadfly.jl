using Gadfly

set_default_plot_size(6inch, 3inch)

n = 10
plot(x=rand(n), y=rand(n),
     Guide.xticks(ticks=[0.0, 0.1, 0.9, 1.0]),
     Guide.yticks(ticks=[0.4, 0.5, 0.6]))
