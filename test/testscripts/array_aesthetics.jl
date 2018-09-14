# Test mapping arrays directly to aesthetics without a data frame.

using Gadfly

set_default_plot_size(6inch, 3inch)

plot(x=collect(1:100), y=sort(rand(100)),
     Guide.xlabel("index"), Guide.ylabel("position"), Guide.title("Gadfly Rules"))
