using Gadfly

set_default_plot_size(8inch, 3inch)

dodge1 = plot(x=["a","a"], y=[3,2], color=["red","blue"],
      Geom.bar(position=:dodge));
dodge2 = plot(x=["a","a","b","b"], y=[3,2,1,2], color=["red","blue","red","blue"],
      Geom.bar(position=:dodge));
stack1 = plot(x=["a","a"], y=[3,2], color=["red","blue"],
      Geom.bar(position=:stack));
stack2 = plot(x=["a","a","b","b"], y=[3,2,1,2], color=["red","blue","red","blue"],
      Geom.bar(position=:stack));

gridstack([dodge1 dodge2; stack1 stack2])
