using Compose, Gadfly

set_default_plot_size(6inch, 3inch)

srand(123)
plot(x=rand(20), y=rand(20), color=repeat(["A","B"], inner=10),
     Guide.colorkey(title="Species", labels=["Name1","Name2"], pos=[0.85w,-0.3h])
     )
