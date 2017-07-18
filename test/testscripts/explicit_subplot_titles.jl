using Gadfly

set_default_plot_size(6inch, 3inch)

plot(x=rand(20), y=rand(20), xgroup=vcat(fill("A", 10), fill("B", 10)),
     Geom.subplot_grid(Geom.point),
     Guide.xlabel("Species"),
     Guide.ylabel("Important Measurements"),
     Guide.title("Title Everything"))

# Not sure how to apply little titles to the subplots or if anyone would want
# to so I won't try for now.
