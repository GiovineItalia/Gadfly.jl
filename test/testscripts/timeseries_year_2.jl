using Gadfly, DataArrays, RDatasets, Base.Dates

set_default_plot_size(6inch, 3inch)

economics = dataset("HistData", "Prostitutes")

if Pkg.installed("RData") < v"0.4.0"
    # NOTE: I know these aren't unix times, but I'm not sure what they are, and this
    # is just a test so it doesn't matter.
    economics[:Date] = DateTime[unix2datetime(d) for d in economics[:Date]]
end

p = plot(economics, x=:Date, y=:Count, Geom.line)
