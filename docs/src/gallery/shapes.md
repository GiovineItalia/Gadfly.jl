# Shapes

## [`Shape.square`](@ref) and friends

```@example
using Gadfly, RDatasets
set_default_plot_size(21cm, 8cm)

p1 = plot(dataset("HistData","DrinksWages"), x="Wage", y="Drinks", 
    shape=[Shape.square], Scale.y_log10)

aww, mws = dataset("MASS", "Animals"), dataset("quantreg", "Mammals")
p2 = plot( layer(aww, x=:Body, y=:Brain, shape=["Brain weight"]),
    layer(mws, x=:Weight, y=:Speed, shape=["Run speed"]),
    Scale.x_log10, Scale.y_log10, Guide.xlabel("Body weight"),
    Guide.ylabel("Brain weight and Run speed"),
    Theme(point_shapes=[Shape.circle, Shape.star1], alphas=[0.0],
        discrete_highlight_color=identity) )
hstack(p1, p2)
```
