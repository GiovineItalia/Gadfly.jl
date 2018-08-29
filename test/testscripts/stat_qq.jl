using Gadfly, Distributions, Random

set_default_plot_size(6inch, 16inch)

Random.seed!(1234)

x = rand(Normal(), 100)
y = rand(Normal(10), 100)

xd = Normal()
yd = Normal(10)

# two numeric vectors
pl1 = plot(x=x, y=y, Stat.qq, Geom.point)

# one numeric and one Distribution
pl2 = plot(x=x, y=yd, Stat.qq, Geom.point)
pl3 = plot(x=xd, y=y, Stat.qq, Geom.point)

# Apply different scales to x and y
pl4 = plot(x=x, y=exp.(y), Stat.qq, Geom.point, Scale.y_log10)
pl5= plot(x=exp.(x), y=y, Stat.qq, Geom.point, Scale.x_log10)

# Apply scales to Distributions
z = rand(Exponential(), 100)
pl5 = plot(x=z, y=Exponential(), Stat.qq, Geom.point)
pl6 = plot(x=log.(z), y=Exponential(), Stat.qq, Geom.point)
pl7 = plot(x=log.(z), y=Exponential(), Stat.qq, Geom.point, Scale.y_log)
pl8 = plot(x=z, y=Exponential(), Stat.qq, Geom.point, Scale.x_log, Scale.y_log)

# by analogy with Stat.func, computed (.y) aes should be scaled:
#plot(xmin=[1], xmax=[15], y=[exp], Stat.func, Geom.line)
# (y value is log(exp(x), or y=x)
#plot(xmin=[1], xmax=[15], y=[exp], Stat.func, Geom.line, Scale.y_log)

vstack(pl1, pl2, pl3, pl4, pl5, pl6, pl7, pl8)
