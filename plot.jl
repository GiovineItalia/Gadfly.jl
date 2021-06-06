using Gadfly

I = 1:10
position = :right

p =
plot(x=I, y=I.*2,
    Guide.yticks(; position), Guide.ylabel(; position))
draw(SVG("tmp.svg"), p)
