using Gadfly

set_default_plot_size(6inch, 3inch)

n = 10
plot(x=rand(n), y=rand(n), color=1000.^rand(n),
     Scale.color_log10(minvalue=1, maxvalue=1e3))
