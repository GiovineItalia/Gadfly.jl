using Gadfly, RDatasets, Dates

set_default_plot_size(6inch, 3inch)

economics = dataset("ggplot2", "economics")
dates = Date[Date(d) for d in economics.Date]
economics.Date = dates

p = plot(economics, x=:Date, y=:Unemploy, Geom.line)
