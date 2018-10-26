using Gadfly

set_default_plot_size(6inch, 3inch)

plot(x=[1.23603, 1.34652, 1.31271, 1.00791, 1.48861, 1.21097, 1.95192, 1.9999, 1.25166, 1.98667],
     y=[1.55575, 1.43711, 1.42472, 1.77322, 1.28119, 1.20947, 1.25138, 1.02037, 1.2877, 1.85951],
     Scale.x_log10(minvalue=1.0, maxvalue=10),
     Scale.y_log10(minvalue=1.0, maxvalue=10))
