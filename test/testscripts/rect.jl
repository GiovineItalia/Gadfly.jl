using DataFrames, Gadfly

set_default_plot_size(6inch, 3inch)

D = DataFrame(x1=[0,0.5], y1=[0,0.5], x2=[1,1.5], y2=[1,1.5])
pb = plot(D, xmin=:x1, ymin=:y1, xmax=:x2, ymax=:y2, Geom.rect)
