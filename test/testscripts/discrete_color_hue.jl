using Gadfly, Colors

plot(ones(10,3).*[1 2 3], x=Row.index, y=Col.value, color=Col.index,
        Geom.line, Scale.color_discrete_hue(x->range(RGB(1,0,0), stop=RGB(0,0,1), length=x)))
