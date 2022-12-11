using Gadfly, DataFrames
set_default_plot_size(6inch, 3inch)

test = DataFrame(x=[1:100; 1:100],
                 y=[1:100; 100:-1:1],
                 z = repeat(["a", "b"], inner = 100));

p1 = plot(test,
          Geom.line,
          x=:x, y=:y, color = :z,
          alpha=[0.1]);

p2 = plot(test,
          Geom.line,
          x=:x, y=:y,
          alpha = :z,
          Theme(alphas=[1.0,0.5]));

hstack(p1,p2)
