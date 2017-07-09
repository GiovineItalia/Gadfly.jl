using Gadfly

set_default_plot_size(6inch, 3inch)

n = 10
plot(x=rand(n), y=rand(n), color=8.^rand(n),
     Scale.color_log2(minvalue=1, maxvalue=8))
