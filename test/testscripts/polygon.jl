using Gadfly

set_default_plot_size(8inch, 3inch)

x = [0, 1, 1, 2, 2, 3, 3, 2, 2, 1, 1, 0, 4, 5, 5, 4]
y = [0, 0, 1, 1, 0, 0, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3]
group = reduce(vcat, fill.(["H", "I"], [12,4]))


p1 = plot(x=x, y=y, group=group, Geom.polygon(preserve_order=false, fill=true))
p2 = plot(x=x, y=y, group=group, Geom.polygon(preserve_order=true, fill=false),
    Theme(line_width=2mm), linestyle=[:dash], color=[colorant"orange"] )

hstack(p1, p2)
