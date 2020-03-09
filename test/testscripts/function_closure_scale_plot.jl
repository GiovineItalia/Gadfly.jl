using Gadfly

set_default_plot_size(6inch, 3inch)

closure(a) = [x -> a[i]*x for i in 1:length(a)]
plot(closure(1:2), 0, 2π, Scale.y_log10())
