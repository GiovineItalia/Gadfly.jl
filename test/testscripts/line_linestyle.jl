using DataFrames, Gadfly
using StatsBase: winsor
set_default_plot_size(6inch, 3inch)

labs = [ "exp", "sqrt", "log", "winsor", "linear"]
funcs = [ x->60*(1 .- exp.(-0.2*x)), x->sqrt.(x)*10, x->log.(x)*10, x->winsor(x, prop=0.15), x->x*0.6 ]
x = [1.0:30;]
D = vcat([DataFrame(x=x, y=f(x), linev=l) for (f,l) in zip(funcs, labs)]...)

p1 = plot(D, x=:x, y=:y, linestyle=:linev, Geom.line )
p2 = plot(D, x=:x, y=:y, linestyle=:linev, Geom.line,
   Scale.linestyle_discrete(levels=["exp", "log", "sqrt", "linear", "winsor"]) )
hstack(p1,p2)
