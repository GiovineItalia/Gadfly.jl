using Gadfly, DataFrames, DelimitedFiles

set_default_plot_size(6inch, 3inch)

dlm, varnames = readdlm(joinpath(dirname(@__DIR__), "data","issue120.csv"),
                        ',', header=true)
df = DataFrame(dlm, vec(Symbol.(varnames)))
plot(df, x=:x1, y=:x2)
