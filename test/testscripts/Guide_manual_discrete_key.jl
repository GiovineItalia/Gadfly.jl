using Gadfly

set_default_plot_size(5inch, 3inch)

# This test covers the issues #509 and #1005 

aes = Gadfly.Aesthetics()
theme = Theme(point_size=4pt, discrete_highlight_color=identity, alphas=[0.2], 
    key_swatch_color="gray", key_max_columns=3)
labels = ["Ideal","Premium","Very Good","Good"]
key1 = Guide.manual_color_key("Key 1", labels, size=[3pt])
key2 = Guide.manual_color_key("Key 2", labels, ["blue","orange"], shape=1:2)
key3 = Guide.manual_discrete_key("Key 3", labels, color=1:3, shape=1:3)

guides = [render(g, theme, aes)[1].ctxs  for g in (key1, key2, key3)] 
gridstack([guides[i][j] for i in 1:3, j in 1:2])
