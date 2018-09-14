
# issue 1018
using Compose, DataFrames, Gadfly
Gadfly.push_theme(Theme(default_color=colorant"black", background_color="white"))

xscale = Scale.x_continuous(format=:plain)
gp = Geom.polygon(preserve_order=true)
D = DataFrame(x=[0, 0, 10^6, 10^6], y=[0, 10, 10, 0])

# Padding
# In absolute units:
pa = plot(D, x=:x, y=:y, gp, xscale, style(plot_padding=[10mm,10mm,5mm,5mm]))
# In relative units (relative to width & height of plot)
pb = plot(D, x=:x, y=:y, gp, xscale, style(plot_padding=[0.05w,0.05w,0.2h,0.2h]))
# 1mm padding on all sides, note x-axis right label gets cut deliberately
pc = plot(D, x=:x, y=:y, gp, xscale, style(plot_padding=[1mm]))
p = hstack(pa,pb,pc)

Gadfly.pop_theme()
return p
