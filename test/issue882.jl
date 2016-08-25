using Gadfly

# check that calling `plot` in the following format
#   (::Array{Any,1}, ::Gadfly.#plot, ::Gadfly.Geom.#density, 
#          ::Gadfly.Guide.XLabel, ::Gadfly.Guide.YLabel)
# does not raise an ambiguity MethodError on Julia v0.5+
plot(x=1:10, y=1:10, color=1:10, Geom.density,
                   Guide.xlabel("foo"), Guide.ylabel("bar"))
