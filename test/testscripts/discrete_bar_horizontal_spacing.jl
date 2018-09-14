using RDatasets, Gadfly

set_default_plot_size(6inch, 3inch)

plot(dataset("plm", "Cigar"), x=:Sales, y=:Year, Scale.y_discrete,
        Geom.bar(orientation=:horizontal), 
        Theme(bar_spacing=1mm, minor_label_font_size=5pt))

