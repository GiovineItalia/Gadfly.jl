using Gadfly, RDatasets
set_default_plot_size(6.6inch, 3.3inch)

salaries = dataset("car","Salaries")
salaries.Salary /= 1000.0
salaries.Discipline = ["Discipline $(x)" for x in salaries.Discipline]

plot(salaries[salaries.Rank.=="Prof",:], x=:YrsService, y=:Salary, xgroup=:Discipline,
    Geom.subplot_grid(Geom.hexbin(xbincount=20, ybincount=20)),
    Scale.xgroup(levels=["Discipline A", "Discipline B"])
)
