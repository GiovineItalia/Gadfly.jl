using Gadfly, RDatasets, Dates

set_default_plot_size(6inch, 3inch)

approval = dataset("Zelig", "approval")
dates = Date[Date(y, m)
             for (y, m) in zip(approval[:Year], approval[:Month])]
approval[:Date] = dates

p = plot(approval, x="Date", y="Approve", Geom.line)
