using Compose, DataFrames, Gadfly, RDatasets, Statistics
set_default_plot_size(21cm, 8cm)

salaries = dataset("car","Salaries")
salaries.Salary /= 1000.0
salaries.Discipline = ["Discipline $(x)" for x in salaries.Discipline]
df = by(salaries, [:Rank,:Discipline], :Salary=>mean, :Salary=>std)
df.ymin, df.ymax = df.Salary_mean.-df.Salary_std, df.Salary_mean.+df.Salary_std
df.label = string.(round.(Int, df.Salary_mean))

p1 = plot(df, x=:Discipline, y=:Salary_mean, color=:Rank, 
    Scale.x_discrete(levels=["Discipline A", "Discipline B"]),
    ymin=:ymin, ymax=:ymax, Geom.errorbar, Stat.dodge,
    Geom.bar(position=:dodge), 
    Scale.color_discrete(levels=["Prof", "AssocProf", "AsstProf"]),
    Guide.colorkey(title="", pos=[0.76w, -0.38h]),
    Theme(bar_spacing=0mm, stroke_color=c->"black")
)
p2 = plot(df, x=:Salary_mean, y=:Discipline, color=:Rank, 
    Scale.y_discrete(levels=["Discipline A", "Discipline B"]),
    label=:label, Geom.label(position=:centered), Stat.dodge(position=:stack, axis=:y),
    Geom.bar(position=:stack, orientation=:horizontal),
    Guide.yticks(orientation=:vertical), Guide.ylabel(nothing)
)
hstack(p1, p2)
