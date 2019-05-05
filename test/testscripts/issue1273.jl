using Gadfly

value=[-18.6652, -7.58777, -51.805, -6.93211, -9.62291, -7.51249, -9.62291, -17.9648, -16.8868, -17.9648, -8.79069]
key=["A", "B", "C", "A", "B", "C", "A", "B", "C", "A", "B"]

plot(x=key, y=value, color=key, Geom.boxplot)
