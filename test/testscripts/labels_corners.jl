using Gadfly

plot(x=[1,2,3,3,1], y=[1,2,3,1,3], label=["LL","M","UR","LR","UL"],
    Geom.point, Geom.label)
