using Gadfly

hstack(plot(y=[1,2,3],shape=[Shape.vline], Theme(discrete_highlight_color=x->x)),
       plot(y=[1,2,3],shape=[Shape.hline], Theme(discrete_highlight_color=x->x)))
