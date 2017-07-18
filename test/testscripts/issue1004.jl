using Gadfly

set_default_plot_size(6inch, 3inch)

plot(x=rand(12), y=rand(12), color=repeat(["a","b","c"], outer=[4]),
     Scale.color_discrete_manual("red","purple","green"))
