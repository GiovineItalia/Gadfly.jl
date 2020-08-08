using Compose, DataFrames, Gadfly

set_default_plot_size(6.6inch,3inch)

df = DataFrame( 
    A=["A","B","C","D","A","C","D","B"],
    B=[1,1,1,1,2,2,2,2],
    C=[ 12059, 57263, 79003, 13125, 25268, 13291, 17365, 30154]
)
df.xmin = df.B .- 0.4
df.xmax = df.B .+ 0.4

theme1 = Theme(bar_spacing=0.2cx)
p1 = plot(df, xmin=:xmin, xmax=:xmax, y=:C, color=:A, Geom.bar(position=:stack))
p2 = plot(df, x=:B, y=:C, color=:A, Geom.bar(position=:stack), theme1)
hstack(p1, p2)