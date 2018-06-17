using Gadfly

p1 = plot(x=[1,2,3,3,1], y=[1,2,3,1,3], label=["LL","M","UR","LR","UL"],
          Geom.point, Geom.label)
p2 = plot(x = [1,2,3], y = [1,2,3], label = ["one","two","three"],
          Coord.cartesian(xmin=0, xmax=4, ymin=0, ymax=4),
          Geom.point, Geom.label)

hstack(p1,p2)
