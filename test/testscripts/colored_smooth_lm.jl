using Gadfly

set_default_plot_size(6inch, 8inch)

x1 = rand(40)
y1 = 4 .* x1 .+ 2 .+ randn(40)
x2 = rand(40)
y2 = -6 .* x2 .+ 3 .+ randn(40)
x  = [x1;x2]
y  = [y1;y2]
col = [fill("Slope 4",40); fill("Slope -6",40)]
plot(x=x,y=y,colour=col, Geom.point, Geom.smooth(method=:lm))
