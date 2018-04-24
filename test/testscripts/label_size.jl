using Gadfly

p1 = plot(x=[1,1,1], y=[1,2,3], size=[1mm,2mm,4mm], Geom.point,
    label=["qwerQWER","asdfASDF","zxcvZXCV"], Geom.label(position=:dynamic, hide_overlaps=false));
p2 = plot(x=[1,1,1], y=[1,2,3], Geom.point,
    label=["qwerQWER","asdfASDF","zxcvZXCV"], Geom.label(position=:dynamic, hide_overlaps=false));
p3 = plot(x=[1,1,1], y=[1,2,3], size=[1mm,2mm,4mm], Geom.point,
    label=["qwerQWER","asdfASDF","zxcvZXCV"], Geom.label(position=:right, hide_overlaps=false));
p4 = plot(x=[1,1,1], y=[1,2,3], Geom.point,
    label=["qwerQWER","asdfASDF","zxcvZXCV"], Geom.label(position=:right, hide_overlaps=false));
gridstack([p1 p2; p3 p4])
