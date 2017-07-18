using Gadfly

set_default_plot_size(6inch, 3inch)

n = 10
plot(x=1+rand(n), y=1+rand(n),
     Scale.x_log10(minvalue=1.0, maxvalue=10),
     Scale.y_log10(minvalue=1.0, maxvalue=10))
