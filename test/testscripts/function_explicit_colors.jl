using Gadfly

set_default_plot_size(6inch, 3inch)

plot([sin, cos], color=["sin", "cos"], 0, 25)
