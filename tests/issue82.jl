
using Gadfly, DataArrays, DataFrames

a = DataFrame(diff = PooledDataArray(Float64[1,2,3,3,3,4,3,2]))
plot(a, x="diff", Geom.histogram)

