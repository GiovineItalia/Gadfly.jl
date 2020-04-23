using Gadfly

set_default_plot_size(5.6inch, 5inch)

parse_colorant = Gadfly.parse_colorant
cs = ["red", "green", "blue"]
shps = ["circle", "square", "triangle"]
szs = ["1mm", "2mm", "3mm"]

plot(x=rand(100), y=rand(100), color=rand(cs, 100),
    shape=rand(shps, 100), size=rand(szs, 100),
    Scale.color_discrete(c->parse_colorant.(cs), levels=cs),
    Scale.size_discrete2(s->[1mm, 2mm, 3mm], levels=szs),
    Scale.shape_discrete(levels=shps),
    Theme(key_swatch_color="gray", key_swatch_size=2mm,
      point_shapes=[Shape.circle,Shape.square,Shape.utriangle])
)
