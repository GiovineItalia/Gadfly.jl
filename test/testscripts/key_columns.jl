
using Gadfly

set_default_plot_size(14cm, 8cm)

# Issue #1344

datas = Gadfly.Data(color= ["D", "A", "C", "D", "A", "C", "D", "D", "A", "B"],
        shape=["E", "F", "F", "E", "G", "E", "E", "G", "H"])
scales = [Scale.color_discrete(levels=["A","B","C","D"]), Scale.shape_discrete(levels=["E","F","G","H"]) ]
aes = Scale.apply_scales(scales, datas)
theme1 = Theme(key_max_columns=4)
guides = [render(g, theme1, aes[1])[1].ctxs  for g in (Guide.colorkey(), Guide.shapekey())] 

gridstack([guides[i][j] for i in 1:2, j in 1:4])
