using Gadfly

set_default_plot_size(6inch, 3inch)

x = rand(10);y=rand(10);
plot(x=x,y=y,Guide.manual_color_key("Title", ["One", "Two"], ["green","blue"]))
