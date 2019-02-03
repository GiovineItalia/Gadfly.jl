using Gadfly, RDatasets

set_default_plot_size(6inch, 6inch)

iris = dataset("datasets", "iris")
sp = unique(iris[:Species])
Dhl = DataFrame(yint=[3.0, 4.0, 2.5, 3.5, 2.5, 4.0], Species=repeat(sp, inner=[2]) )

function plotxg(scalexg::Scale.DiscreteScale)
    plot(iris, xgroup=:Species,
        Geom.subplot_grid(
            layer( x=:SepalLength, y=:SepalWidth, Geom.point),
            layer(Dhl, xgroup=:Species, yintercept=:yint, Geom.hline(color="red", style=:dot) ),
            ),
    scalexg,
    Theme(plot_padding=[0mm])
)
end

scales =    [Scale.xgroup(), Scale.xgroup(levels=["virginica","setosa","versicolor"]), Scale.xgroup(order=[3,1,2])]
plots = plotxg.(scales)

vstack(plots...)
