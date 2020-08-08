using DataFrames, Gadfly, Distributions, Random

set_default_plot_size(3.5inch, 16inch)

Random.seed!(1234)

x = rand(Normal(), 100)
y = rand(Normal(10), 100)


# two numeric vectors
pl1 = plot(x=x, y=y, Stat.qq, Geom.point)


y = randn(100).+5
ds = fit.([Normal, LogNormal], [y]) 
df = [DataFrame(y=randn(100), g=g) for g in ["Sample1", "Sample2"]]

theme = Theme(discrete_highlight_color=c->nothing, alphas=[0.5], 
    point_size=2pt, key_position=:inside)
yeqx(x=-3:3) = layer(x=x, Geom.abline(color="gray80"))
gck = Guide.colorkey(title="")

# Plot title describes plots
pl2 = plot(x=Normal(), y=randn(100), Stat.qq, yeqx, theme,
    Guide.title("1 sample, 1 Distribution"))
pl3 = plot(vcat(df...), x=Normal(), y=:y, Stat.qq, color=:g, yeqx, 
    gck, theme, Guide.title("2 samples, 1 Distribution"))
pl4 = plot(x=ds, y=y, color=["Normal", "LogNormal"], Stat.qq, yeqx(3:8), 
    gck, theme, Guide.title("1 sample, 2 Distributions"))

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
