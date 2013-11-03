
module Geom

using Color
using Compose
using DataFrames
using Gadfly

import Compose.combine # Prevent DataFrame.combine from taking over.
import Gadfly: render, element_aesthetics, inherit, escape_id, default_statistic
import Iterators
import Iterators: cycle, product, distinct, take


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


include("geom/bar.jl")
include("geom/boxplot.jl")
include("geom/errorbar.jl")
include("geom/label.jl")
include("geom/line.jl")
include("geom/point.jl")
include("geom/rectbin.jl")
include("geom/subplot.jl")
include("geom/hline.jl")
include("geom/vline.jl")

end # module Geom

