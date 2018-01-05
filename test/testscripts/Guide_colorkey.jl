using Gadfly

set_default_plot_size(6inch, 3inch)

plot(x=rand(20), y=rand(20), color=repeat(["A","B"], inner=10),
     Guide.colorkey(title="Species",labels=["Name1","Name2"]))
