using Gadfly

n = 10
plot(x=rand(n), y=rand(n), color=e.^rand(n),
     Scale.color_log(minvalue=1))
