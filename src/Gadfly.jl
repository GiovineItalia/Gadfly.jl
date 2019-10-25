module Gadfly

using Colors
using Compat
using Compose
using DataStructures
using JSON
using Showoff
using IndirectArrays
using CategoricalArrays
using Printf
using Base64
using Requires

import IterTools
import IterTools: distinct, drop, chain
import Compose: draw, hstack, vstack, gridstack, parse_colorant
import Base: +, -, /, *,
             copy, push!, show, getindex, cat,
             show, isfinite, display
import Distributions: Distribution

export Plot, Layer, Theme, Col, Row, Scale, Coord, Geom, Guide, Stat, Shape, render, plot,
       style, layer, spy, set_default_plot_size, set_default_plot_format, prepare_display

@deprecate circle Shape.circle
@deprecate square Shape.square
@deprecate diamond Shape.diamond
@deprecate cross Shape.cross
@deprecate xcross Shape.xcross
@deprecate utriangle Shape.utriangle
@deprecate dtriangle Shape.dtriangle
@deprecate star1 Shape.star1
@deprecate star2 Shape.star2
@deprecate hexagon Shape.hexagon
@deprecate octogon Shape.octogon
@deprecate hline Shape.hline
@deprecate vline Shape.vline

# Re-export some essentials from Compose
export SVGJS, SVG, PGF, PNG, PS, PDF, draw, inch, mm, cm, px, pt, color, @colorant_str, vstack, hstack, title, gridstack


function link_terminalextensions()
    @debug "Loading TerminalExtensions support into Gadfly"
    include("terminalextensions.jl")
end

function __init__()
    # Define an XML namespace for custom attributes
    Compose.xmlns["gadfly"] = "http://www.gadflyjl.org/ns"
    if haskey(ENV, "GADFLY_THEME")
        theme = ENV["GADFLY_THEME"]
        try
            push_theme(Symbol(strip(theme)))
        catch err
            @warn "Error loading Gadfly theme $theme (set by GADFLY_THEME env variable)"
            show(err)
        end
    else
        push_theme(:default)
    end
    pushdisplay(GadflyDisplay())

    @require DataFrames="a93c6f00-e57d-5684-b7b6-d8193f3e46c0" link_dataframes()
    @require TerminalExtensions="d3a6a179-465e-5219-bd3e-0137f7fd17c7" link_terminalextensions()
end


const ColorOrNothing = Union{Colorant, (Nothing)}

element_aesthetics(::Any) = []
input_aesthetics(::Any) = []
output_aesthetics(::Any) = []
default_scales(::Any) = []
default_scales(x::Any, t) = default_scales(x)
default_statistic(::Any) = Stat.identity()
element_coordinate_type(::Any) = Coord.cartesian

function aes2str(aes)
  list = join([string('`',x,'`') for x in aes], ", ", " and ")
  if length(aes)>1
    return string("the ",list," aesthetics")
  else
    return string("the ",list," aesthetic")
  end
end

abstract type Element end
abstract type ScaleElement       <: Element end
abstract type CoordinateElement  <: Element end
abstract type GeometryElement    <: Element end
abstract type GuideElement       <: Element end
abstract type StatisticElement   <: Element end


include("misc.jl")
include("ticks.jl")
include("color_misc.jl")
include("varset.jl")
include("shapes.jl")
include("data.jl")
include("aesthetics.jl")
include("mapping.jl")
include("scale.jl")
include("theme.jl")
include("open_file.jl")


### rename to ElementOrFunctionOrTheme ?
# The layer and plot functions can also take functions that are evaluated with
# no arguments and are expected to produce an element.
const ElementOrFunction{T <: Element} = Union{Element, Base.Callable, Theme}

const gadflyjs = joinpath(dirname(Base.source_path()), "gadfly.js")


# Set prefereed canvas size when rendering a plot without an explicit call to
# `draw`.
"""
    set_default_plot_size(width::Compose.MeasureOrNumber,
                          height::Compose.MeasureOrNumber)

Sets preferred canvas size when rendering a plot without an explicit call to draw.  Units
can be `inch`, `cm`, `mm`, `pt`, or `px`.
"""
set_default_plot_size(width::Compose.MeasureOrNumber, height::Compose.MeasureOrNumber) =
        Compose.set_default_graphic_size(width, height)


### NOT SURE THIS DOES ANYTHING.
"""
    set_default_plot_format(fmt::Symbol)

Sets the default plot format.
"""
set_default_plot_format(fmt::Symbol) = Compose.set_default_graphic_format(fmt)


# A plot has zero or more layers. Layers have a particular geometry and their
# own data, which is inherited from the plot if not given.
mutable struct Layer <: Element
    data_source
    mapping::Dict
    statistics::Vector{StatisticElement}
    geom::GeometryElement
    theme::Union{Nothing, Theme}
    order::Int
end
Layer() = Layer(nothing, Dict(), StatisticElement[], Geom.nil(), nothing, 0)
Layer(l::Layer) = Layer(l.data_source, l.mapping, l.statistics, l.geom, l.theme, l.order)
copy(l::Layer) = Layer(l)

"""
    layer(data_source::Union{AbstractDataFrame, Void}),
          elements::ElementOrFunction...; mapping...) -> [Layers]

Create a layer element based on the data in `data_source`, to later input into
`plot`.  `elements` can be [Statistics](@ref lib_stat), [Geometries](@ref
lib_geom), and/or [Themes](@ref) (but not Scales, Coordinates, or Guides).
`mapping` are aesthetics.

# Examples

```
ls=[]
append!(ls, layer(y=[1,2,3], Geom.line))
append!(ls, layer(y=[3,2,1], Geom.point))
plot(ls..., Guide.title("layer example"))
```
"""
function layer(data_source,
               elements::ElementOrFunction...; mapping...)
    lyr = Layer()
    lyr.data_source = data_source
    lyr.mapping = cleanmapping(Dict(mapping))
    if haskey(mapping, :order)
        lyr.order = mapping[:order]
    end
    lyrs = Layer[lyr]
    for element in elements
        add_plot_element!(lyrs, element)
    end
    lyrs
end

"""
    layer(elements::ElementOrFunction...; mapping...) =
          layer(nothing, elements...; mapping...) -> [Layers]
"""
layer(elements::ElementOrFunction...; mapping...) =
        layer(nothing, elements...; mapping...)

add_plot_element!(lyrs::Vector{Layer}, arg::T) where {T<:Element} =
        error("Layers can't be used with elements of type $(typeof(arg))")

add_plot_element!(lyrs::Vector{Layer}, arg::ScaleElement) =
        error("Scales cannot be passed to layers, they must be specified at the plot level.")

function add_plot_element!(lyrs::Vector{Layer}, arg::GeometryElement)
    if lyrs[end].geom !== Geom.nil()
        push!(lyrs, copy(lyrs[end]))
    end
    lyrs[end].geom = arg
end

add_plot_element!(lyrs::Vector{Layer}, arg::Base.Callable) = add_plot_element!(lyrs, arg())

function add_plot_element!(lyrs::Vector{Layer}, arg::StatisticElement)
    for lyr in lyrs
        push!(lyr.statistics, arg)
    end
end

add_plot_element!(lyrs::Vector{Layer}, arg::Theme) = [lyr.theme = arg for lyr in lyrs]


# A full plot specification.
mutable struct Plot
    layers::Vector{Layer}
    data_source
    data::Data
    scales::Vector{ScaleElement}
    statistics::Vector{StatisticElement}
    coord::Union{Nothing, CoordinateElement}
    guides::Vector{GuideElement}
    theme::Theme
    mapping::Dict
end
Plot() = Plot(Layer[], nothing, Data(), ScaleElement[], StatisticElement[],
      nothing, GuideElement[], current_theme(), Dict())

layers(p::Plot) = p.layers

function add_plot_element!(p::Plot, arg::GeometryElement)
    if !isempty(p.layers) && isa(p.layers[end].geom, Geom.Nil)
        p.layers[end].geom = arg
    else
        layer = Layer()
        layer.geom = arg
        push!(p.layers, layer)
    end
end

function add_plot_element!(p::Plot, arg::StatisticElement)
    if isempty(p.layers)
        push!(p.layers, Layer())
    end

    push!(p.layers[end].statistics, arg)
end

add_plot_element!(p::Plot, arg::Function) = add_plot_element!(p, arg())
add_plot_element!(p::Plot, arg::ScaleElement) = push!(p.scales, arg)
add_plot_element!(p::Plot, arg::CoordinateElement) = p.coord = arg
add_plot_element!(p::Plot, arg::GuideElement) = push!(p.guides, arg)
add_plot_element!(p::Plot, arg::Layer) = push!(p.layers, arg)
add_plot_element!(p::Plot, arg::Vector{Layer}) = append!(p.layers, arg)
add_plot_element!(p::Plot, f::Type{T}) where {T <: Element} = add_plot_element!(p, f())
add_plot_element!(p::Plot, theme::Theme) = p.theme = theme


# because a call to layer() expands to a vector of layers (one for each Geom
# supplied), we need to allow Vector{Layer} to count as an Element for the
# purposes of plot().
const ElementOrFunctionOrLayers = Union{ElementOrFunction, Vector{Layer}}


"""
    plot(data_source::Union{AbstractMatrix, AbstractDataFrame},
         elements::ElementOrFunctionOrLayers...; mapping...) -> Plot

Create a new plot by specifying a `data_source`, zero or more `elements`
([Scales](@ref lib_scale), [Statistics](@ref lib_stat), [Coordinates](@ref
lib_coord), [Geometries](@ref lib_geom), [Guides](@ref lib_guide),
[Themes](@ref), and/or [Layers](@ref)), and a `mapping` of aesthetics to
columns or expressions of the data.

# Examples

```
my_frame = DataFrame(time=1917:2018, price=1.02.^(0:101))
plot(my_frame, x=:time, y=:price, Geom.line)

my_matrix = [1917:2018 1.02.^(0:101)]
plot(my_matrix, x=Col.value(1), y=Col.value(2), Geom.line,
     Guide.xlabel("time"), Guide.ylabel("price"))
```
"""
function plot(data_source,
              elements::ElementOrFunctionOrLayers...; mapping...)
    return plot(data_source, Dict(mapping), elements...)
end

"""
    plot(elements::ElementOrFunctionOrLayers...; aesthetics...) -> Plot

Create a new plot of the vectors in 'aesthetics'.  Optional `elements`
([Scales](@ref lib_scale), [Statistics](@ref lib_stat), [Coordinates](@ref
lib_coord), [Geometries](@ref lib_geom), [Guides](@ref lib_guide),
[Themes](@ref), and/or [Layers](@ref)) control the layout, labelling, and
transformation of the data.

# Examples

```
plot(x=collect(1917:2018), y=1.02.^(0:101), Geom.line)
```
"""
function plot(elements::ElementOrFunctionOrLayers...; mapping...)
    plot(nothing, Dict(mapping), elements...)
end

"""
    plot(data_source::Union{Void, AbstractMatrix, AbstractDataFrame},
         mapping::Dict, elements::ElementOrFunctionOrLayers...) -> Plot

The old fashioned (pre-named arguments) version of plot.  This version takes an
explicit mapping dictionary, mapping aesthetics symbols to expressions or
columns in the data frame.
"""
function plot(data_source,
              mapping::Dict, elements::ElementOrFunctionOrLayers...)
    mapping = cleanmapping(mapping)
    p = Plot()
    for element in elements
        add_plot_element!(p, element)
    end

    p.data_source = evalmapping!(mapping, data_source, p.data)
    p.mapping = mapping

    return p
end


include("poetry.jl")


function Base.push!(p::Plot, element::ElementOrFunctionOrLayers)
    add_plot_element!(p, element)
    return p
end


# Turn a graph specification into a graphic.
#
# This is where magic happens (sausage is made). Processing all the parts of the
# plot is actually pretty simple. It's made complicated by trying to handle
# defaults. With that aside, plots are made in the following steps.
#
#    I. Apply scales to transform raw data to the form expected by the aesthetic.
#   II. Apply statistics to the scaled data. Statistics are essentially functions
#       that map one or more aesthetics to one or more aesthetics.
#  III. Apply coordinates. Currently all this does is figure out the coordinate
#       system used by the plot panel canvas.
#   IV. Render geometries. This gives us one or more compose forms suitable to be
#       composed with the plot's panel.
#    V. Render guides. Guides are conceptually very similar to geometries but with
#       the ability to be placed outside of the plot panel.
#
#  Finally there is a very important call to layout_guides which puts everything
#  together.
#
# Args:
#   plot: a plot to render.
#
# Returns:
#   A compose Canvas containing the graphic.
#
function render_prepare(plot::Plot)
    if isempty(plot.layers)
        layer = Layer()
        layer.geom = Geom.point()
        push!(plot.layers, layer)
    end

    # TODO: When subplots are given in multiple layers, we should rearrange,
    # putting the layers in one subplot instead.
    if sum([isa(layer.geom, Geom.SubplotGeometry) for layer in plot.layers]) > 1
        error("""
              Subplot geometries can not be used in multiple layers. Instead
              use layers within one subplot geometry.
              """)
    end

    # Process layers, filling inheriting mappings or data from the Plot where
    # they are missing.
    datas = Array{Data}(undef, length(plot.layers))
    for (i, layer) in enumerate(plot.layers)
        if layer.data_source === nothing && isempty(layer.mapping)
            layer.data_source = plot.data_source
            layer.mapping = plot.mapping
            datas[i] = plot.data
        else
            datas[i] = Data()

            if layer.data_source === nothing
                layer.data_source = plot.data_source
            end

            if isempty(layer.mapping)
                layer.mapping = plot.mapping
            end

            evalmapping!(layer.mapping, layer.data_source, datas[i])
        end
        if isa(layer.geom, Geom.Nil); layer.geom = Geom.point(); end # see #1062
    end

    # We need to process subplot layers somewhat as though they were regular
    # plot layers. This is the only way scales, etc, can be consistently
    # applied.
    subplot_datas = Data[]
    for (layer, layer_data) in zip(plot.layers, datas)
        if isa(layer.geom, Geom.SubplotGeometry)
            for subplot_layer in layers(layer.geom)
                subplot_data = Data()
                if subplot_layer.data_source === nothing
                    subplot_layer.data_source = layer.data_source
                end

                if isempty(subplot_layer.mapping)
                    subplot_layer.mapping = layer.mapping
                end

                evalmapping!(subplot_layer.mapping, subplot_layer.data_source, subplot_data)
                push!(subplot_datas, subplot_data)
            end
        end
    end

    # Figure out the coordinates
    coord = plot.coord
    for layer in plot.layers
        coord_type = element_coordinate_type(layer.geom)
        if coord === nothing
            coord = coord_type()
        elseif typeof(coord) != coord_type
            error("Plot uses multiple coordinates: $(typeof(coord)) and $(coord_type)")
        end
    end

    # Add default statistics for geometries.
    layer_stats = Array{Vector{StatisticElement}}(undef, length(plot.layers))
    for (i, layer) in enumerate(plot.layers)
        layer_stats[i] = isempty(layer.statistics) ? ( isa(layer.geom, Geom.SubplotGeometry) ?
                default_statistic(layer.geom) : [default_statistic(layer.geom)] ) : layer.statistics
    end

    # auto-enumeration: add Stat.x/y_enumerate when x and y is needed but only
    # one defined
    for (i, layer) in enumerate(plot.layers)
        layer_needed_aes = element_aesthetics(layer.geom)
        layer_defined_aes = Set{Symbol}()
        union!(layer_defined_aes, keys(layer.mapping))
        for stat in layer.statistics
            union!(layer_defined_aes, output_aesthetics(stat))
        end

        if mapreduce(x->in(x,layer_needed_aes),|,[:x,:xmax,:xmin]) &&
                mapreduce(y->in(y,layer_needed_aes),|,[:y,:ymax,:ymin])
            if !mapreduce(x->in(x,layer_defined_aes),|,[:x,:xmax,:xmin])
                pushfirst!(layer_stats[i], Stat.x_enumerate)
            elseif !mapreduce(y->in(y,layer_defined_aes),|,[:y,:ymax,:ymin])
                pushfirst!(layer_stats[i], Stat.y_enumerate)
            end
        end
    end

    used_aesthetics = Set{Symbol}()
    for layer in plot.layers
        union!(used_aesthetics, element_aesthetics(layer.geom))
    end

    for stats in layer_stats, stat in stats
        union!(used_aesthetics, input_aesthetics(stat))
    end

    mapped_aesthetics = Set(keys(plot.mapping))
    for layer in plot.layers
        union!(mapped_aesthetics, keys(layer.mapping))
    end

    defined_unused_aesthetics = setdiff(mapped_aesthetics, used_aesthetics)
    isempty(defined_unused_aesthetics) ||
            @warn "The following aesthetics are mapped, but not used by any geometry:\n" * 
                join(defined_unused_aesthetics, ", ")

    scaled_aesthetics = Set{Symbol}()
    for scale in plot.scales
        union!(scaled_aesthetics, element_aesthetics(scale))
    end

    # Only one scale can be applied to an aesthetic (without getting some weird
    # and incorrect results), so we organize scales into a dict.
    scales = Dict{Symbol, ScaleElement}()
    for scale in plot.scales
        for var in element_aesthetics(scale)
            scales[var] = scale
        end
    end

    unscaled_aesthetics = setdiff(used_aesthetics, scaled_aesthetics)

    _theme(plt, lyr) = lyr.theme == nothing ? plt.theme : lyr.theme

    # Add default scales for statistics.
    layer_stats_with_theme = map(plot.layers, layer_stats) do l, stats
        map(s->(s, _theme(l, plot)), collect(stats))
    end

    for element in Iterators.flatten(([(s, plot.theme) for s in plot.statistics],
                         [(l.geom, _theme(plot, l)) for l in plot.layers],
                         layer_stats_with_theme...))

        for scale in default_scales(element...)
            # Use the statistics default scale only when it covers some
            # aesthetic that is not already scaled.
            scale_aes = Set(element_aesthetics(scale))
            if !isempty(intersect(scale_aes, unscaled_aesthetics))
                for var in scale_aes
                    scales[var] = scale
                end
                setdiff!(unscaled_aesthetics, scale_aes)
            end
        end
    end

    # Assign scales to mapped aesthetics first.
    for var in unscaled_aesthetics
        in(var, mapped_aesthetics) || continue

        var_data = getfield(plot.data, var)
        if var_data == nothing
            for data in datas
                var_layer_data = getfield(data, var)
                if var_layer_data != nothing
                    var_data = var_layer_data
                    break
                end
            end
        end

        var_data == nothing && continue

        t = classify_data(var_data)
        if scale_exists(t, var)
            scale = get_scale(t, var, plot.theme)
            scale_aes = Set(element_aesthetics(scale))
            for var in scale_aes
                scales[var] = scale
            end
        end
    end

    for var in unscaled_aesthetics
        (haskey(plot.mapping, var) || haskey(scales, var)) && continue

        t = :categorical
        for data in Iterators.flatten((datas, subplot_datas))
            val = getfield(data, var)
            if val != nothing && val != :categorical
                t = classify_data(val)
            end
        end

        if scale_exists(t, var)
            scale = get_scale(t, var, plot.theme)
            scale_aes = Set(element_aesthetics(scale))
            for var in scale_aes
                scales[var] = scale
            end
        end
    end

    # Avoid clobbering user-defined guides with default guides (e.g.
    # in the case of labels.)
    guides = copy(plot.guides)
    explicit_guide_types = Set()
    for guide in guides
        push!(explicit_guide_types, typeof(guide))
    end

    statistics = Set{StatisticElement}()
    for statistic in plot.statistics
        push!(statistics, statistic)
    end

    # Default guides and statistics
    facet_plot = true
    for layer in plot.layers
        if typeof(layer.geom) != Geom.subplot_grid
            facet_plot = false
            break
        end
    end

    if !facet_plot
        in(Guide.PanelBackground, explicit_guide_types) || push!(guides, Guide.background())
        in(Guide.QuestionMark, explicit_guide_types) || push!(guides, Guide.questionmark())
        in(Guide.HelpScreen, explicit_guide_types) || push!(guides, Guide.helpscreen())
        in(Guide.CrossHair, explicit_guide_types) || push!(guides, Guide.crosshair())
        in(Guide.XTicks, explicit_guide_types) || push!(guides, Guide.xticks())
        in(Guide.YTicks, explicit_guide_types) || push!(guides, Guide.yticks())
    end

    for guide in guides
        push!(statistics, default_statistic(guide))
    end

    mapped_and_used = function(vs)
        any(Bool[in(v, mapped_aesthetics) && in(v, used_aesthetics) for v in vs])
    end

    choose_name = function(vs, fallback)
        for v in vs
            if haskey(plot.data.titles, v)
                return plot.data.titles[v]
            end
        end

        for v in vs
            for data in datas
                if haskey(data.titles, v)
                    return data.titles[v]
                end
            end
        end

        fallback
    end

    if mapped_and_used(x_axis_label_aesthetics) &&
        !in(Guide.XLabel, explicit_guide_types)
        label = choose_name(x_axis_label_aesthetics, "x")
        if facet_plot && haskey(plot.data.titles, :xgroup)
            label = string(label, " <i><b>by</b></i> ", plot.data.titles[:xgroup])
        end

        push!(guides, Guide.xlabel(label))
    end

    if mapped_and_used(y_axis_label_aesthetics) &&
       !in(Guide.YLabel, explicit_guide_types)
        label = choose_name(y_axis_label_aesthetics, "y")
        if facet_plot && haskey(plot.data.titles, :ygroup)
            label = string(label, " <i><b>by</b></i> ", plot.data.titles[:ygroup])
        end

        push!(guides, Guide.ylabel(label))
    end

    # I. Scales
    layer_aess = Scale.apply_scales(IterTools.distinct(values(scales)),
                                    datas..., subplot_datas...)

    # set defaults for key titles
    keyvars = [:color, :shape]
    for (i, layer) in enumerate(plot.layers)
        for kv in keyvars
            fflag = (getfield(layer_aess[i], Symbol(kv,"_key_title")) == nothing) && haskey(layer.mapping, kv) && !isa(layer.mapping[kv], AbstractArray)
            fflag && setfield!(layer_aess[i], Symbol(kv,"_key_title"), string(layer.mapping[kv]))
        end
    end

    for kv in keyvars
        fflag = (getfield(layer_aess[1], Symbol(kv,"_key_title")) == nothing) && haskey(plot.mapping, kv) && !isa(plot.mapping[kv], AbstractArray)
        fflag && setfield!(layer_aess[1], Symbol(kv,"_key_title"), string(plot.mapping[kv]))
    end

    # Auto-update color scale if shape==color
    catdatas = vcat(datas, subplot_datas)
    shapev = getfield.(catdatas, :shape)
    di = (shapev.!=nothing) .& (shapev.== getfield.(catdatas, :color))

    supress_colorkey = false
    for (aes, data) in zip(layer_aess[di], catdatas[di])
        aes.shape_key_title==nothing && (aes.shape_key_title=aes.color_key_title="Shape")
        colorf = scales[:color].f
        scales[:color] =  Scale.color_discrete(colorf, levels=scales[:shape].levels, order=scales[:shape].order)
        Scale.apply_scale(scales[:color], [aes], Gadfly.Data(color=getfield(data,:color))  )
        supress_colorkey=true
    end


    # IIa. Layer-wise statistics
    if !facet_plot
        for (stats, aes) in zip(layer_stats, layer_aess)
            Stat.apply_statistics(stats, scales, coord, aes)
        end
    end

    # IIb. Plot-wise Statistics
    plot_aes = concat(layer_aess...)
    statistics = collect(statistics)
    Stat.apply_statistics(statistics, scales, coord, plot_aes)

    # Add some default guides determined by defined aesthetics
    keytypes = [Guide.ColorKey, Guide.ShapeKey]
    supress_keys = false
    for layer in plot.layers
        if isa(layer.geom, Geom.SubplotGeometry) && any(haskey.((layer.geom.guides,), keytypes))
            supress_keys = true
            break
        end
    end

    if supress_colorkey
        deleteat!(keytypes, 1)
        deleteat!(keyvars, 1)
    end

    if !supress_keys
        for (KT, kv) in zip(keytypes, keyvars)
            fflag = !all([getfield(aes, kv)==nothing for aes in [plot_aes, layer_aess...]])
            fflag && !in(KT, explicit_guide_types) &&  push!(guides, KT())
        end
    end

    # build arrays of scaled aesthetics for layers within subplots
    layer_subplot_aess = Array{Vector{Aesthetics}}(undef, length(plot.layers))
    layer_subplot_datas = Array{Vector{Data}}(undef, length(plot.layers))
    j = 1
    for (i, layer) in enumerate(plot.layers)
        layer_subplot_aess[i] = Aesthetics[]
        layer_subplot_datas[i] = Data[]
        if isa(layer.geom, Geom.SubplotGeometry)
            for subplot_layer in layers(layer.geom)
                push!(layer_subplot_aess[i], layer_aess[length(datas) + j])
                push!(layer_subplot_datas[i], subplot_datas[j])
                j += 1
            end
        end
    end

    return (plot, coord, plot_aes,
            layer_aess, layer_stats, layer_subplot_aess, layer_subplot_datas,
            scales, guides)
end

"""
    render(plot::Plot) -> Context

Render `plot` to a `Compose` context.
"""
function render(plot::Plot)
    (plot, coord, plot_aes,
     layer_aess, layer_stats, layer_subplot_aess, layer_subplot_datas,
     scales, guides) = render_prepare(plot)

    root_context = render_prepared(plot, coord, plot_aes, layer_aess,
                                   layer_stats, layer_subplot_aess,
                                   layer_subplot_datas,
                                   scales, guides)

    ctx =  pad_inner(root_context, plot.theme.plot_padding...)

    if plot.theme.background_color != nothing
        compose!(ctx, (context(order=-1000000),
                        fill(plot.theme.background_color),
                        stroke(nothing), rectangle()))
    end

    return ctx
end


# Render a plot given a precomputed Aesthetics object for each layer.
#
# Additionally, without all the work to choose reasonable defaults performed by
# `render`. This is a separate function from `render` to facilitate rendering
# subplots.
#
# Args:
#   plot: Plot to be rendered.
#   aess: A vector of precomputed Aesthetics objects of the same length
#       as plot.layers.
#   layer_stats: A vector of statistic elements of the same length as
#       plot.layers.
#   layer_subplot_aesthetics: An array of aesthetics for each layer in the plot.
#       If the layer in a subplot geometry, the array is scaled data for each
#       sub-geometry, otherwise it's empty. I just melted your brain, didn't I?
#   scales: Dictionary mapping an aesthetics symbol to the scale applied to it.
#   statistics: Statistic elements applied plot-wise.
#   guides: Guide elements indexed by type. (Only one type of each guide may
#       be in the same plot.)
#   preserve_plot_context_size: Don't squish the plot to fit the guides.
#       Guides will be drawn outside the context
#
# Returns:
#   A Compose context containing the rendered plot.
#
function render_prepared(plot::Plot,
                         coord::CoordinateElement,
                         plot_aes::Aesthetics,
                         layer_aess::Vector{Aesthetics},
                         layer_stats::Vector{Vector{StatisticElement}},
                         layer_subplot_aess::Vector{Vector{Aesthetics}},
                         layer_subplot_datas::Vector{Vector{Data}},
                         scales::Dict{Symbol, ScaleElement},
                         guides::Vector{GuideElement};
                         table_only=false,
                         dynamic=true)
    # III. Coordinates
    plot_context = Coord.apply_coordinate(coord, vcat(plot_aes,
                                          layer_aess), scales)

    # IV. Geometries
    themes = Theme[layer.theme === nothing ? plot.theme : layer.theme
                   for layer in plot.layers]
    zips = trim_zip(plot.layers, layer_aess,
                                                   layer_subplot_aess,
                                                   layer_subplot_datas,
               themes)

    compose!(plot_context,
             [compose(context(order=layer.order), render(layer.geom, theme, aes,
                                                         subplot_aes, subplot_data,
                                                         scales))
              for (layer, aes, subplot_aes, subplot_data, theme) in zips]...)

    # V. Guides
    guide_contexts = Any[]
    for guide in guides
        guide_context = render(guide, plot.theme, plot_aes, dynamic)
        if guide_context != nothing
            append!(guide_contexts, guide_context)
        end
    end

    tbl = Guide.layout_guides(plot_context, coord,
                              plot.theme, guide_contexts...)
    if table_only
        return tbl
    end

    c = compose!(context(), tbl)
    class = "plotroot"
    if haskey(scales, :x) && isa(scales[:x], Scale.ContinuousScale) && scales[:x].scalable
        class = string(class, " xscalable")
    end
    if haskey(scales, :y) && isa(scales[:y], Scale.ContinuousScale) && scales[:y].scalable
        class = string(class, " yscalable")
    end

    compose(c, svgclass(class), jsinclude(gadflyjs, ("Gadfly", "Gadfly")))
end


# A convenience version of Compose.draw that let's you skip the call to render.
"""
    draw(backend::Compose.Backend, p::Plot)

A convenience version of `Compose.draw` without having to call render.
"""
draw(backend::Compose.Backend, p::Plot) = draw(backend, render(p))

"""
    title(ctx::Context, str::String, props::Property...) -> Context

Add a title string to a group of plots, typically created with [`vstack`](@ref),
[`hstack`](@ref), or [`gridstack`](@ref).

# Examples

```
p1 = plot(x=[1,2], y=[3,4], Geom.line);
p2 = plot(x=[1,2], y=[4,3], Geom.line);
title(hstack(p1,p2), "my latest data", Compose.fontsize(18pt), fill(colorant"red"))
```
"""
title(ctx::Context, str::String, props::Compose.Property...) = vstack(
    compose(context(0, 0, 1, 0.1), text(0.5, 1.0, str, hcenter, vbottom), props...),
    compose(context(0, 0, 1, 0.9), ctx))

# Convenience stacking functions
"""
    vstack(ps::Union{Plot,Context}...)
    vstack(ps::Vector)

Arrange plots into a vertical column.  Use `context()` as a placeholder for an
empty panel.  Heterogeneous vectors must be typed.  See also [`hstack`](@ref),
[`gridstack`](@ref), and [`Geom.subplot_grid`](@ref).

# Examples

```
p1 = plot(x=[1,2], y=[3,4], Geom.line);
p2 = Compose.context();
vstack(p1, p2)
vstack(Union{Plot,Compose.Context}[p1, p2])
```
"""
vstack(ps::Union{Plot,Context}...) = vstack([typeof(p)==Plot ? render(p) : p for p in ps]...)
vstack(ps::Vector{Plot}) = vstack(ps...)
vstack(ps::Vector{Union{Plot,Context}}) = vstack(ps...)

"""
    hstack(ps::Union{Plot,Context}...)
    hstack(ps::Vector)

Arrange plots into a horizontal row.  Use `context()` as a placeholder for an
empty panel.  Heterogeneous vectors must be typed.  See also [`vstack`](@ref),
[`gridstack`](@ref), and [`Geom.subplot_grid`](@ref).

# Examples

```
p1 = plot(x=[1,2], y=[3,4], Geom.line);
p2 = Compose.context();
hstack(p1, p2)
hstack(Union{Plot,Compose.Context}[p1, p2])
```
"""
hstack(ps::Union{Plot,Context}...) = hstack([typeof(p)==Plot ? render(p) : p for p in ps]...)
hstack(ps::Vector{Plot}) = hstack(ps...)
hstack(ps::Vector{Union{Plot,Context}}) = hstack(ps...)

"""
    gridstack(ps::Matrix{Union{Plot,Context}})

Arrange plots into a rectangular array.  Use `context()` as a placeholder for
an empty panel.  Heterogeneous matrices must be typed.  See also [`hstack`](@ref)
and [`vstack`](@ref).

# Examples

```
p1 = plot(x=[1,2], y=[3,4], Geom.line);
p2 = Compose.context();
gridstack([p1 p1; p1 p1])
gridstack(Union{Plot,Compose.Context}[p1 p2; p2 p1])
```
"""
gridstack(ps::Matrix{Plot}) = _gridstack(ps)
gridstack(ps::Matrix{Union{Plot,Context}}) = _gridstack(ps)
_gridstack(ps::Matrix) = gridstack(map(p->typeof(p)==Plot ? render(p) : p, ps))

# show functions for all supported compose backends.


function show(io::IO, m::MIME"text/html", p::Plot)
    buf = IOBuffer()
    svg = SVGJS(buf, Compose.default_graphic_width,
                Compose.default_graphic_height, false)
    draw(svg, p)
    show(io, m, svg)
end

function show(io::IO, m::MIME"image/svg+xml", p::Plot)
    buf = IOBuffer()
    svg = SVG(buf, Compose.default_graphic_width,
              Compose.default_graphic_height, false)
    draw(svg, p)
    show(io, m, svg)
end

function show(io::IO,m::Union{MIME"application/juno+plotpane",
                              MIME"application/prs.juno.plotpane+html"}, p::Plot)
    buf = IOBuffer()
    svg = SVGJS(buf, Compose.default_graphic_width,
                Compose.default_graphic_height, false)
    draw(svg, p)
    show(io, "text/html", svg)
end

try
    getfield(Compose, :Cairo) # throws if Cairo isn't being used
    global show
    function show(io::IO, ::MIME"image/png", p::Plot)
        draw(PNG(io, Compose.default_graphic_width,
                 Compose.default_graphic_height), p)
    end
catch
end

try
    getfield(Compose, :Cairo) # throws if Cairo isn't being used
    global show
    function show(io::IO, ::MIME"application/postscript", p::Plot)
        draw(PS(io, Compose.default_graphic_width,
             Compose.default_graphic_height), p);
    end
catch
end

function show(io::IO, ::MIME"text/plain", p::Plot)
    write(io, "Plot(...)")
end

function default_mime()
    if Compose.default_graphic_format == :png
        "image/png"
    elseif Compose.default_graphic_format == :svg
        "image/svg+xml"
    elseif Compose.default_graphic_format == :html
        "text/html"
    elseif Compose.default_graphic_format == :ps
        "application/postscript"
    elseif Compose.default_graphic_format == :pdf
        "application/pdf"
    else
        ""
    end
end

struct GadflyDisplay <: AbstractDisplay end

"""
    display(p::Plot)

Render `p` to a multimedia display, typically an internet browser.
This function is handy when rendering by `plot` has been suppressed
with either trailing semi-colon or by calling it within a function.
"""
function display(d::GadflyDisplay, p::Union{Plot,Compose.Context})
    if showable("text/html", p)
        display(d,"text/html", p)
        return
    elseif showable("image/png", p)
        display(d,"image/png", p)
        return
    elseif showable("application/pdf", p)
        display(d,"application/pdf", p)
        return
    elseif showable("image/svg+xml", p)
        display(d,"image/svg+xml", p)
        return
    elseif showable("application/postscript", p)
        display(d,"application/postscript", p)
        return
    end
    throw(MethodError)
end

# Fallback display method. When there isn't a better option, we write to a
# temporary file and try to open it.
function display(d::GadflyDisplay, ::MIME"image/png", p::Union{Plot,Compose.Context})
    filename = string(tempname(), ".png")
    output = open(filename, "w")
    draw(PNG(output, Compose.default_graphic_width,
             Compose.default_graphic_height), p)
    close(output)
    open_file(filename)
end

function display(d::GadflyDisplay, ::MIME"image/svg+xml", p::Union{Plot,Compose.Context})
    filename = string(tempname(), ".svg")
    output = open(filename, "w")
    draw(SVG(output, Compose.default_graphic_width,
             Compose.default_graphic_height), p)
    close(output)
    open_file(filename)
end

function display(d::GadflyDisplay, ::MIME"text/html", p::Union{Plot,Compose.Context})
    filename = string(tempname(), ".html")
    output = open(filename, "w")

    plot_output = IOBuffer()
    draw(SVGJS(plot_output, Compose.default_graphic_width,
               Compose.default_graphic_height, false), p)
    plotsvg = String(take!(plot_output))

    write(output,
        """
        <!DOCTYPE html>
        <html>
          <head>
            <title>Gadfly Plot</title>
            <meta charset="utf-8">
          </head>
          <body style="margin:0">
            $(plotsvg)
          </body>
        </html>
        """)
    close(output)
    open_file(filename)
end

function display(d::GadflyDisplay, ::MIME"application/postscript", p::Union{Plot,Compose.Context})
    filename = string(tempname(), ".ps")
    output = open(filename, "w")
    draw(PS(output, Compose.default_graphic_width,
            Compose.default_graphic_height), p)
    close(output)
    open_file(filename)
end

function display(d::GadflyDisplay, ::MIME"application/pdf", p::Union{Plot,Compose.Context})
    filename = string(tempname(), ".pdf")
    output = open(filename, "w")
    draw(PDF(output, Compose.default_graphic_width,
             Compose.default_graphic_height), p)
    close(output)
    open_file(filename)
end

include("coord.jl")
include("geometry.jl")
include("guide.jl")
include("statistics.jl")


# All aesthetics must have a scale. If none is given, we use a default.
# The default depends on whether the input is discrete or continuous (i.e.,
# PooledDataVector or DataVector, respectively).
const default_aes_scales = Dict{Symbol, Dict}(

    :distribution => Dict{Symbol, Any}(
        :x => Scale.x_distribution(),
        :y => Scale.y_distribution()
    ),

    :functional => Dict{Symbol, Any}(
        :z      => Scale.z_func(),
        :y      => Scale.y_func(),
        :shape  => Scale.shape_identity(),
        :size   => Scale.size_identity(),
        :color  => Scale.color_identity(),
    ),

    :numerical => Dict{Symbol, Any}(
        :x           => Scale.x_continuous(),
        :xmin        => Scale.x_continuous(),
        :xmax        => Scale.x_continuous(),
        :xintercept  => Scale.x_continuous(),
        :xend        => Scale.x_continuous(),
        :yend        => Scale.y_continuous(),
        :y           => Scale.y_continuous(),
        :ymin        => Scale.y_continuous(),
        :ymax        => Scale.y_continuous(),
        :yintercept  => Scale.y_continuous(),
        :slope      => Scale.slope_continuous(),
        :intercept  => Scale.y_continuous(),
        :middle      => Scale.y_continuous(),
        :upper_fence => Scale.y_continuous(),
        :lower_fence => Scale.y_continuous(),
        :upper_hinge => Scale.y_continuous(),
        :lower_hinge => Scale.y_continuous(),
        :xgroup      => Scale.xgroup(),
        :ygroup      => Scale.ygroup(),
        :shape       => Scale.shape_discrete(),
        :size        => Scale.size_continuous(),
        :group       => Scale.group_discrete(),
        :label       => Scale.label(),
        :alpha       => Scale.alpha_continuous(),
        :linestyle   => Scale.linestyle_discrete()
    ),

    :categorical => Dict{Symbol, Any}(
        :x          => Scale.x_discrete(),
        :xmin       => Scale.x_discrete(),
        :xmax       => Scale.x_discrete(),
        :xintercept => Scale.x_discrete(),
        :xend       => Scale.x_discrete(),
        :yend       => Scale.y_discrete(),
        :y          => Scale.y_discrete(),
        :ymin       => Scale.y_discrete(),
        :ymax       => Scale.y_discrete(),
        :yintercept => Scale.y_discrete(),
        :xgroup     => Scale.xgroup(),
        :ygroup     => Scale.ygroup(),
        :shape      => Scale.shape_discrete(),
        :size       => Scale.size_discrete(),
        :group      => Scale.group_discrete(),
        :label      => Scale.label(),
        :alpha       => Scale.alpha_discrete(),
        :linestyle  => Scale.linestyle_discrete()
    )
)


get_scale(::Val{t}, ::Val{var}, theme::Theme) where {t,var} = default_aes_scales[t][var]
get_scale(t::Symbol, var::Symbol, theme::Theme) = get_scale(Val{t}(), Val{var}(), theme)

### Override default getters for color scales
get_scale(::Val{:categorical}, ::Val{:color}, theme::Theme=current_theme()) =
        theme.discrete_color_scale
get_scale(::Val{:numerical}, ::Val{:color}, theme::Theme=current_theme()) =
        theme.continuous_color_scale


function scale_exists(t::Symbol, var::Symbol)
    if !haskey(default_aes_scales, t) || !haskey(default_aes_scales[t], var)
        method = methods(get_scale, (Val{t}, Val{var}, Theme))
        catchall = methods(get_scale, (Val{1}, Val{nothing}, Theme))
        first(method) !== first(catchall)
    else
        true
    end
end


# Determine whether the input is categorical or numerical

const CategoricalType = Union{AbstractString, Bool, Symbol}

classify_data(data::AbstractArray{T, N}) where {N, T <: Union{CategoricalType,Missing}}        = :categorical
classify_data(data::AbstractArray{T, N}) where {N, T <: Union{Base.Callable,Measure,Colorant}} = :functional
classify_data(data::CategoricalArray) = :categorical
classify_data(data::T) where {T <: Base.Callable} = :functional
classify_data(data::AbstractArray) = :numerical
classify_data(data::Distribution) = :distribution

function classify_data(data::AbstractArray{Any})
    for val in data
        if isa(val, CategoricalType)
            return :categorical
        end
    end
    :numerical
end

# Axis labels are taken whatever is mapped to these aesthetics, in order of
# preference.
const x_axis_label_aesthetics = [:x, :xmin, :xmax]
const y_axis_label_aesthetics = [:y, :ymin, :ymax]

end # module Gadfly
