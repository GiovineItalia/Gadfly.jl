
using Gadfly, DataArrays, RDatasets

#df = dataset("car", "SLID")
#df = df[(df[:Language] .!= "Other") & !isna(df[:Language]),:]

#plot(df, x=:Wages, y=:Education, color=:Age,
     #shape=[string(a, "/", b) for (a, b) in zip(df[:Sex], df[:Language])],
     #Geom.point)
     

using Gadfly, DataArrays, RDatasets

plot(dataset("datasets", "iris"),
     x=:SepalLength, y=:SepalWidth, color=:PetalLength, shape=:Species,
     Geom.point)
