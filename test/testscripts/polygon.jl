using Gadfly

set_default_plot_size(6inch, 3inch)

plot(x=[0, 1, 1, 2, 2, 3, 3, 2, 2, 1, 1, 0, 4, 5, 5, 4],
     y=[0, 0, 1, 1, 0, 0, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3],
     group=["H", "H", "H", "H", "H", "H", "H", "H",
            "H", "H", "H", "H", "I", "I", "I", "I"],
     Geom.polygon(preserve_order=false, fill=true))

plot(x=[0, 1, 1, 2, 2, 3, 3, 2, 2, 1, 1, 0, 4, 5, 5, 4],
     y=[0, 0, 1, 1, 0, 0, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3],
     group=["H", "H", "H", "H", "H", "H", "H", "H",
            "H", "H", "H", "H", "I", "I", "I", "I"],
     Geom.polygon(preserve_order=true, fill=true))
