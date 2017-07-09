using Gadfly

set_default_plot_size(6inch, 3inch)

# jitter used to not work for categorical data

plot(x=rand(['a','b','c','d'],100), y=rand(100),
      Geom.point, Scale.x_discrete, Stat.x_jitter(range=0.2))
