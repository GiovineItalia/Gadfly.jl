using Gadfly

set_default_plot_size(6inch, 8inch)

c = ["red", "blue"]
dodge1 = plot(x=["a","a"], y=[3,2], color=c, Geom.bar(position=:dodge))
dodge2 = plot(x=["a","a","b","b"], y=[3,2,1,2], color=[c;c], Geom.bar(position=:dodge))
stack1 = plot(x=["a","a"], y=[3,2], color=c, Geom.bar(position=:stack))
stack2 = plot(x=["a","a","b","b"], y=[3,2,1,2], color=[c;c], Geom.bar(position=:stack))
identity1 = plot(x=["a","a"], y=[3,2], color=c, alpha=[0.5], Geom.bar(position=:identity))
identity2 = plot(x=["a","a","b","b"], y=[3,2,1,2], color=[c;c], alpha=[0.5],
    Geom.bar(position=:identity))

gridstack([dodge1 dodge2; stack1 stack2; identity1 identity2])
