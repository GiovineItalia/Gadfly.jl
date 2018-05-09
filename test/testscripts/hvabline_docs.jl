using Gadfly, RDatasets, Compose

set_default_plot_size(6inch, 9inch)

vstack(
    plot(sin, 0, 25, xintercept=[0, pi, 2pi, 3pi], yintercept=[0, -1, 1],
        Geom.hline(style=[:dot,[1mm,1mm],:solid]), Geom.vline(style=:dashdot)),
    plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point,
        yintercept=[2.5, 4.0], Geom.hline(color=["orange","red"], size=[2mm,3mm])),
    plot(dataset("ggplot2", "mpg"), x="Cty", y="Hwy", Geom.point,
        intercept=[0], slope=[1], Geom.abline(color="red", style=:dash),
        Guide.annotation(compose(context(), text(0.1w, 0.9h, "y=x", hright, vbottom),
            fill(colorant"red"), svgclass("marker")))) )
