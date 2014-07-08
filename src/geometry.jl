
module Geom

using Color
using Compose
using DataArrays
using DataStructures
using Gadfly

import Compose.combine # Prevent DataFrame.combine from taking over.
import Gadfly: render, element_aesthetics, inherit, escape_id,
               default_statistic, setfield!, set, ScaleElement,
               svg_color_class_from_label
import Iterators
import Iterators: cycle, product, distinct, takestrict, chain, repeated


# Geometry that renders nothing.
immutable Nil <: Gadfly.GeometryElement
end

const nil = Nil

function render(geom::Nil, theme::Gadfly.Theme, aes::Gadfly.Aesthetics,
                scales::Dict{Symbol, ScaleElement})
end


# Catchall
function default_statistic(::Gadfly.GeometryElement)
    Gadfly.Stat.identity()
end


include("geom/bar.jl")
include("geom/boxplot.jl")
include("geom/errorbar.jl")
include("geom/hexbin.jl")
include("geom/hline.jl")
include("geom/label.jl")
include("geom/line.jl")
include("geom/point.jl")
include("geom/rectbin.jl")
include("geom/subplot.jl")
include("geom/vline.jl")
include("geom/ribbon.jl")

end # module Geom

