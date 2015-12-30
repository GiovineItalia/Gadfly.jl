using Gadfly

n = 10
plot(x=rand(n), y=rand(n), color=8.^rand(n),
     Scale.color_log2(minvalue=1, maxvalue=8))
