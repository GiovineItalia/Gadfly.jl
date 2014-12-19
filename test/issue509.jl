using Gadfly

x = rand(10);y=rand(10);
plot(x=x,y=y,Guide.manual_color_key("Title", ["One", "Two"], ["green","blue"]))
