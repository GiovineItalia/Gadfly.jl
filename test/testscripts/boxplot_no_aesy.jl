using Gadfly, DataFrames

x = collect(11:20)
a = x .* 3 .+ 4
b = a .- 1
c = a .- 2
d = a .- 3
     
df = DataFrame(x=x, a=a, b=b, c=c, d=d, s=repeat(["A"],inner=10))
plot(df, x="x", upper_fence="a", upper_hinge="b", lower_hinge="c", lower_fence="d",
     Geom.boxplot)
