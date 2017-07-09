using Gadfly

set_default_plot_size(6inch, 3inch)

plot(x=rand(20), y=rand(20), Guide.xrug, Guide.yrug)
