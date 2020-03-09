
using Gadfly

set_default_plot_size(14cm, 8cm)

# Issue #1344

datas = Gadfly.Data(color= ["D", "A", "C", "D", "A", "C", "D", "D", "A", "B"],
    shape=["E", "F", "F", "E", "G", "E", "E", "G", "H"], size=["I","I","K","J","L","L","I","J","K","L"])
scales = [Scale.color_discrete(levels=["A","B","C","D"]), Scale.shape_discrete(levels=["E","F","G","H"]),
    Scale.size_discrete2(levels=["I","J","K","L"])]

aes = Scale.apply_scales(scales, datas)
theme1 = Theme(key_max_columns=4, point_size=5pt, key_swatch_shape=Shape.circle)
guides = [render(g, theme1, aes[1])[1].ctxs  for g in (Guide.colorkey(), Guide.shapekey(), Guide.sizekey())] 

gridstack([guides[i][j] for i in 1:3, j in 1:4])
