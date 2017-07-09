using Gadfly

set_default_plot_size(6inch, 3inch)

# make sure Theme.{discrete,continuous}_highlight_color works for Geom.point.

discrete_with_highlights = plot(x=rand(1:3,100),y=rand(100),color=rand(["a","b"],100),
            Geom.point, Stat.x_jitter);
discrete_without_highlights = plot(x=rand(1:3,100),y=rand(100),color=rand(["a","b"],100),
            Geom.point, Stat.x_jitter, Theme(discrete_highlight_color=x->x));
continuous_with_highlights = plot(x=rand(1:3,100),y=rand(100),color=rand(1:2,100),
            Geom.point, Stat.x_jitter);
continuous_without_highlights = plot(x=rand(1:3,100),y=rand(100),color=rand(1:2,100),
            Geom.point, Stat.x_jitter, Theme(continuous_highlight_color=x->x));
gridstack([discrete_with_highlights   discrete_without_highlights
           continuous_with_highlights continuous_without_highlights])
