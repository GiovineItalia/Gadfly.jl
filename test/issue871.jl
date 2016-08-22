using Gadfly

# check for method ambiguity using Geom.bar, #871
plot(x=1:10, y=1:10, Geom.bar, Guide.xlabel("foo"), Guide.ylabel("bar"))
