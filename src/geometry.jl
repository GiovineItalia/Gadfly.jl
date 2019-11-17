module Geom

using Colors
using Compose
using DataStructures
using Distributions
using Gadfly
using Measures
using IndirectArrays
using Base.Iterators

import Compose.combine # Prevent DataFrame.combine from taking over.
import Gadfly: render, layers, element_aesthetics, inherit, escape_id,
               default_statistic, default_scales, element_coordinate_type,
               ScaleElement, svg_color_class_from_label, isconcrete,
               concretize, discretize_make_ia
import IterTools: takestrict

const empty_tag = Symbol("")

function subtags(parent_tag, suffixes...)
    if parent_tag == empty_tag
        return map(s->empty_tag, suffixes)
    end
    return map(s->Symbol(parent_tag, "#", s), suffixes)
end


# Geometry that renders nothing.
struct Nil <: Gadfly.GeometryElement
end

const nil = Nil

render(geom::Nil, theme::Gadfly.Theme, aes::Gadfly.Aesthetics,
        data::Gadfly.Data, scales::Dict{Symbol, ScaleElement},
        subplot_layer_aess::Vector{Gadfly.Aesthetics}) = nothing


# Subplot geometries require some more arguments to render. A simpler render
# function is defined and passed through to here for non-subplot geometries.
render(geom::Gadfly.GeometryElement, theme::Gadfly.Theme, aes::Gadfly.Aesthetics,
                subplot_layer_aess::Union{(Nothing), Vector{Gadfly.Aesthetics}},
                subplot_layer_datas::Union{(Nothing), Vector{Gadfly.Data}},
                scales::Dict{Symbol, ScaleElement}) =
        render(geom, theme, aes)

# Catchall
default_statistic(::Gadfly.GeometryElement) = Gadfly.Stat.identity()


include("geom/bar.jl")
include("geom/blank.jl")
include("geom/boxplot.jl")
include("geom/errorbar.jl")
include("geom/hexbin.jl")
include("geom/hvabline.jl")
include("geom/label.jl")
include("geom/line.jl")
include("geom/point.jl")
include("geom/rectbin.jl")
include("geom/subplot.jl")
include("geom/ribbon.jl")
include("geom/violin.jl")
include("geom/polygon.jl")
include("geom/beeswarm.jl")
include("geom/segment.jl")

end # module Geom
