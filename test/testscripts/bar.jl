using RDatasets, Gadfly

set_default_plot_size(8inch, 8inch)

# discrete_bar, discrete_bar_horizontal, discrete_bar_horizontal_spacing, histogram_errorbar
df = dataset("plm", "Cigar")

p1 = plot(df, x=:Year, y=:Sales, Scale.x_discrete, Geom.bar)
p2 = plot(df, x=:Sales, y=:Year, Scale.y_discrete, Geom.bar(orientation=:horizontal))
p3 = plot(df, x=:Sales, y=:Year, Scale.y_discrete,
        Geom.bar(orientation=:horizontal), 
        Theme(bar_spacing=1mm, minor_label_font_size=5pt))
df1 = df[df.State.==1, :]
ymin, ymax = df1.Sales.-20*0.23, df1.Sales.+20*0.34
p4 = plot(df1, x=:Year, y=:Sales, ymin=ymin, ymax=ymax, Geom.bar, Geom.errorbar)


gridstack([p1 p2; p3 p4])
