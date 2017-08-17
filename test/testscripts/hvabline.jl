using Gadfly

set_default_plot_size(12inch, 3inch)

hstack(
    plot(x=[2,3,4],y=[2,3,4],Geom.point,intercept=[0],slope=[1],Geom.abline),
    plot(x=[2,3,4],y=[2,3,4],Geom.point,intercept=[0],Geom.abline),
    plot(x=[2,3,4],y=[2,3,4],Geom.point,slope=[1],Geom.abline),
    plot(x=[2,3,4],y=[2,3,4],Geom.point,intercept=[0.1],Geom.abline),
    plot(x=[2,3,4],y=[2,3,4],Geom.point,slope=[1.1],Geom.abline) )
