
using RDatasets, Gadfly

set_default_plot_size(7inch, 3.3inch)

Gadfly.with_theme(:ggplot) do

    pa = plot(dataset("datasets","iris"),
        x=:PetalWidth, y=:SepalLength, color=:Species, Geom.point,
        Scale.color_discrete(order=[3,2,1]),
        Guide.colorkey(title="Iris", pos=[0.1, 9.3])
    )
    
    pb = plot(dataset("ggplot2","diamonds"), x=:Price, y=:Carat,
        Geom.histogram2d(xbincount=25, ybincount=25),
        Scale.color_log10,
        Scale.x_continuous(format=:plain)
    )
        
    hstack(pa, pb)
end

