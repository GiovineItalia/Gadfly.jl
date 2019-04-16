using DataFrames, Gadfly

set_default_plot_size(21cm, 8cm)

Da = DataFrame(x1 = [0, 0.5], y1 = [0, 0.5], x2 = [0.5, 1], y2 = [0.5, 1])
pa = plot(Da, xmin = :x1, ymin = :y1, xmax = :x2, ymax = :y2, Geom.rect) # Shared corner coordinate.

Db = DataFrame(x1 = [0, 0.5], y1 = [0, 0.5], x2 = [1, 1.5], y2 = [1, 1.5])
pb = plot(Db, xmin = :x1, ymin = :y1, xmax = :x2, ymax = :y2, Geom.rect) # Overlapping rects.

hstack(pa,pb)
