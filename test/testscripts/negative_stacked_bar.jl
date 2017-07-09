using Gadfly

set_default_plot_size(12inch, 6inch)

independent = [1,2,3,1,2,3]
dependent = [4,5,6,1,2,3]
group = [1,1,1,2,2,2]
vpos = plot(x=independent, y=  dependent, color=group, Geom.bar(position=:stack, orientation=:vertical));
hpos = plot(x=  dependent, y=independent, color=group, Geom.bar(position=:stack, orientation=:horizontal));
vneg = plot(x=independent, y= -dependent, color=group, Geom.bar(position=:stack, orientation=:vertical));
hneg = plot(x= -dependent, y=independent, color=group, Geom.bar(position=:stack, orientation=:horizontal));
gridstack([vpos hpos; vneg hneg])
