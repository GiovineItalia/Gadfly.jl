
module Geom

using Colors
using Compat
using Compose
using DataArrays
using DataStructures
using Gadfly

import Compose.combine # Prevent DataFrame.combine from taking over.
import Gadfly: render, layers, element_aesthetics, inherit, escape_id,
               default_statistic, default_scales, element_coordinate_type,
               ScaleElement, svg_color_class_from_label, isconcrete,
               concretize
import Iterators
import Iterators: cycle, product, distinct, takestrict, chain, repeated


# Geometry that renders nothing.
immutable Nil <: Gadfly.GeometryElement
end

const nil = Nil

function render(geom::Nil, theme::Gadfly.Theme, aes::Gadfly.Aesthetics,
                data::Gadfly.Data, scales::Dict{Symbol, ScaleElement},
                subplot_layer_aess::Vector{Gadfly.Aesthetics})
end


# Subplot geometries require some more arguments to render. A simpler render
# function is defined and passed through to here for non-subplot geometries.
function render(geom::Gadfly.GeometryElement, theme::Gadfly.Theme, aes::Gadfly.Aesthetics,
                subplot_layer_aess::Union(Nothing, Vector{Gadfly.Aesthetics}),
                subplot_layer_datas::Union(Nothing, Vector{Gadfly.Data}),
                scales::Dict{Symbol, ScaleElement})
    render(geom, theme, aes)
end


# Catchall
function default_statistic(::Gadfly.GeometryElement)
    return Gadfly.Stat.identity()
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
include("geom/violin.jl")
include("geom/polygon.jl")
include("geom/beeswarm.jl")

end # module Geom

