using DataFrames, Distributions, Gadfly

set_default_plot_size(6inch, 3inch)

beta = Beta(2,2)
Dbeta = DataFrame(x=rand(beta, 10^4))
layer1 = layer(x->pdf(beta, x), 0, 1, Geom.line, Theme(default_color="black"))
p1 = plot(Dbeta, layer1,
    layer(x=:x, Geom.histogram(bincount=20, density=true, limits=(min=0,))),
)
p2 = plot(Dbeta, layer1,
    layer(x=:x, Geom.histogram(bincount=20, density=true, limits=(min=0, max=1)))
)

hstack(p1, p2)
