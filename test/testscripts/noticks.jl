using Gadfly

set_default_plot_size(6inch, 3inch)

plot(x=rand(10), y=rand(10), Guide.xticks(ticks=nothing), Guide.yticks(ticks=nothing))
