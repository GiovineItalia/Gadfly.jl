
module Geom

using Color
using Compose
using DataFrames
using Gadfly

import Compose.combine # Prevent DataFrame.combine from taking over.
import Gadfly.render, Gadfly.element_aesthetics, Gadfly.inherit, Gadfly.escape_id
import Iterators.cycle, Iterators.product, Iterators.distinct


# Geometry that renders nothing.
immutable Nil <: Gadfly.GeometryElement
end

const nil = Nil

function render(geom::Nil, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
end


# Catchall
function default_statistic(::Gadfly.GeometryElement)
    Gadfly.Stat.identity()
end


include("geom/subplot.jl")
include("geom/point.jl")
include("geom/line.jl")
include("geom/bar.jl")
include("geom/rectbin.jl")
include("geom/boxplot.jl")
include("geom/label.jl")

end # module Geom

