using Gadfly

set_default_plot_size(8inch, 3inch)

hstack(
    plot(x=[1,2,3,1],y=[-1,2,3,-4],color=["a","a","a","b"],Geom.bar),
    plot(y=[1,2,3,1],x=[-1,2,3,-4],color=["a","a","a","b"],Geom.bar(orientation=:horizontal)) )
