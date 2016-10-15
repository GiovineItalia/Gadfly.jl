__precompile__()

module Gadfly

using Colors
using Compat
using Compose
using DataArrays
using DataFrames
using DataStructures
using JSON
using Showoff

import Iterators
import Iterators: distinct, drop, chain
import Compose: draw, hstack, vstack, gridstack, isinstalled, parse_colorant, parse_colorant_vec
@compat import Base: +, -, /, *,
             copy, push!, start, next, done, show, getindex, cat,
             show, isfinite, display
import Distributions: Distribution

export Plot, Layer, Theme, Col, Scale, Coord, Geom, Guide, Stat, render, plot,
       style, layer, spy, set_default_plot_size, set_default_plot_format, prepare_display


# Re-export some essentials from Compose
export SVGJS, SVG, PGF, PNG, PS, PDF, draw, inch, mm, cm, px, pt, color, @colorant_str, vstack, hstack


function __init__()
    # Define an XML namespace for custom attributes
    Compose.xmlns["gadfly"] = "http://www.gadflyjl.org/ns"
    if haskey(ENV, "GADFLY_THEME")
        theme = ENV["GADFLY_THEME"]
        try
            push_theme(Symbol(strip(theme)))
        catch err
            warn("Error loading Gadfly theme $theme (set by GADFLY_THEME env variable)")
            show(err)
        end
    else
        push_theme(Juno.isactive() ? :dark : :default)
    end
end


typealias ColorOrNothing @compat(Union{Colorant, (@compat Void)})

element_aesthetics(::Any) = []
input_aesthetics(::Any) = []
output_aesthetics(::Any) = []
default_scales(::Any) = []
default_scales(x::Any, t) = default_scales(x)
default_statistic(::Any) = Stat.identity()
element_coordinate_type(::Any) = Coord.cartesian


abstract Element
abstract ScaleElement       <: Element
abstract CoordinateElement  <: Element
abstract GeometryElement    <: Element
abstract GuideElement       <: Element
abstract StatisticElement   <: Element


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


# The layer and plot functions can also take functions that are evaluated with
# no arguments and are expected to produce an element.
typealias ElementOrFunction{T <: Element} @compat(Union{Element, Base.Callable, Theme})

const gadflyjs = joinpath(dirname(Base.source_path()), "gadfly.js")


# Set prefereed canvas size when rendering a plot without an explicit call to
# `draw`.
"""
```
set_default_plot_size(width::Compose.MeasureOrNumber, height::Compose.MeasureOrNumber)
```
Sets preferred canvas size when rendering a plot without an explicit call to draw
"""
function set_default_plot_size(width::Compose.MeasureOrNumber,
                               height::Compose.MeasureOrNumber)
    Compose.set_default_graphic_size(width, height)
end


"""
```
set_default_plot_format(fmt::Symbol)
```
Sets the default plot format
"""
function set_default_plot_format(fmt::Symbol)
    Compose.set_default_graphic_format(fmt)
end


# A plot has zero or more layers. Layers have a particular geometry and their
# own data, which is inherited from the plot if not given.
type Layer <: Element
    data_source::@compat(Union{(@compat Void), MeltedData, AbstractMatrix, AbstractDataFrame})
    mapping::Dict
    statistics::Vector{StatisticElement}
    geom::GeometryElement
    theme::@compat(Union{(@compat Void), Theme})
    order::Int

    function Layer()
        new(nothing, Dict(), StatisticElement[], Geom.nil(), nothing, 0)
    end

    function Layer(lyr::Layer)
        new(lyr.data_source,
            lyr.mapping,
            lyr.statistics,
            lyr.geom,
            lyr.theme)
    end
end

function copy(lyr::Layer)
    lyr_new = Layer(lyr)
end



"""
```
layer(data_source::@compat(Union{AbstractDataFrame, (@compat Void)}),
               elements::ElementOrFunction...; mapping...)
```
Creates layers based on elements

### Args
* data_source: The data source as a dataframe
* elements: The elements
* mapping: mapping

### Returns
An array of layers
"""
function layer(data_source::@compat(Union{AbstractDataFrame, (@compat Void)}),
               elements::ElementOrFunction...; mapping...)
    mapping = Dict{Symbol, Any}(mapping)
    lyr = Layer()
    lyr.data_source = data_source
    lyr.mapping = cleanmapping(mapping)
    if haskey(mapping, :order)
        lyr.order = mapping[:order]
    end
    lyrs = Layer[lyr]
    for element in elements
        add_plot_element!(lyrs, element)
    end
    lyrs
end


function layer(elements::ElementOrFunction...; mapping...)
    return layer(nothing, elements...; mapping...)
end


function add_plot_element!{T<:Element}(lyrs::Vector{Layer}, arg::T)
    error("Layers can't be used with elements of type $(typeof(arg))")
end


function add_plot_element!(lyrs::Vector{Layer}, arg::ScaleElement)
    error("Scales cannot be passed to layers, they must be specified at the plot level.")
end


function add_plot_element!(lyrs::Vector{Layer}, arg::GeometryElement)
    if ! is(lyrs[end].geom, Geom.nil())
        push!(lyrs, copy(lyrs[end]))
    end
    lyrs[end].geom = arg
end


function add_plot_element!(lyrs::Vector{Layer}, arg::Base.Callable)
    add_plot_element!(lyrs, arg())
end


function add_plot_element!(lyrs::Vector{Layer}, arg::StatisticElement)
    for lyr in lyrs
        push!(lyr.statistics, arg)
    end
end


function add_plot_element!(lyrs::Vector{Layer}, arg::Theme)
    [lyr.theme = arg for lyr in lyrs]
end


# A full plot specification.
type Plot
    layers::Vector{Layer}
    data_source::@compat(Union{(@compat Void), MeltedData, AbstractMatrix, AbstractDataFrame})
    data::Data
    scales::Vector{ScaleElement}
    statistics::Vector{StatisticElement}
    coord::@compat(Union{(@compat Void), CoordinateElement})
    guides::Vector{GuideElement}
    theme::Theme
    mapping::Dict

    function Plot()
        new(Layer[], nothing, Data(), ScaleElement[], StatisticElement[],
            nothing, GuideElement[], current_theme())
    end
end


function layers(p::Plot)
    return p.layers
end


function add_plot_element!(p::Plot, arg::Function)
    add_plot_element!(p, arg())
end


function add_plot_element!(p::Plot, arg::GeometryElement)
    if !isempty(p.layers) && isa(p.layers[end].geom, Geom.Nil)
        p.layers[end].geom = arg
    else
        layer = Layer()
        layer.geom = arg
        push!(p.layers, layer)
    end
end


function add_plot_element!(p::Plot, arg::ScaleElement)
    push!(p.scales, arg)
end


function add_plot_element!(p::Plot, arg::StatisticElement)
    if isempty(p.layers)
        push!(p.layers, Layer())
    end

    push!(p.layers[end].statistics, arg)
end


function add_plot_element!(p::Plot, arg::CoordinateElement)
    p.coord = arg
end


function add_plot_element!(p::Plot, arg::GuideElement)
    push!(p.guides, arg)
end


function add_plot_element!(p::Plot, arg::Layer)
    push!(p.layers, arg)
end


function add_plot_element!(p::Plot, arg::Vector{Layer})
    append!(p.layers, arg)
end


function add_plot_element!{T <: Element}(p::Plot, f::Type{T})
    add_plot_element!(p, f())
end


function add_plot_element!(p::Plot, theme::Theme)
    p.theme = theme
end


# Create a new plot.
#
# Grammar of graphics style plotting consists of specifying a dataset, one or
# more plot elements (scales, coordinates, geometries, etc), and binding of
# aesthetics to columns or expressions of the dataset.
#
# For example, a simple scatter plot would look something like:
#
#     plot(my_data, Geom.point, x="time", y="price")
#
# Where "time" and "price" are the names of columns in my_data.
#
# Args:
#   data_source: Data to be bound to aesthetics.
#   mapping: Aesthetics symbols (e.g. :x, :y, :color) mapped to
#            names of columns in the data frame or other expressions.
#   elements: Geometries, statistics, etc.

# because a call to layer() expands to a vector of layers (one for each Geom
# supplied), we need to allow Vector{Layer} to count as an Element for the
# purposes of plot().
typealias ElementOrFunctionOrLayers @compat(Union{ElementOrFunction, Vector{Layer}})


"""
```
    function plot(data_source::@compat(Union{AbstractMatrix, AbstractDataFrame}),
              elements::ElementOrFunctionOrLayers...; mapping...)
```

Create a new plot.

Grammar of graphics style plotting consists of specifying a dataset, one or
more plot elements (scales, coordinates, geometries, etc), and binding of
aesthetics to columns or expressions of the dataset.

For example, a simple scatter plot would look something like:

plot(my_data, Geom.point, x="time", y="price")

Where "time" and "price" are the names of columns in my_data.

### Args:
* data_source: Data to be bound to aesthetics.
* elements: Geometries, statistics, etc.
* mapping: Aesthetics symbols (e.g. :x, :y, :color) mapped to names of columns in the data frame or other expressions.
"""
function plot(data_source::@compat(Union{AbstractMatrix, AbstractDataFrame}),
              elements::ElementOrFunctionOrLayers...; mapping...)
    mappingdict = Dict{Symbol, Any}(mapping)
    return plot(data_source, mappingdict, elements...)
end


function plot(elements::ElementOrFunctionOrLayers...; mapping...)
    mappingdict = Dict{Symbol, Any}(mapping)
    plot(nothing, mappingdict, elements...)
end


# The old fashioned (pre named arguments) version of plot.
#
# This version takes an explicit mapping dictionary, mapping aesthetics symbols
# to expressions or columns in the data frame.
#
# Args:
#   data_source: Data to be bound to aesthetics.
#   mapping: Dictionary of aesthetics symbols (e.g. :x, :y, :color) to
#            names of columns in the data frame or other expressions.
#   elements: Geometries, statistics, etc.
#
# Returns:
#   A Plot object.
#
"""
```
function plot(data_source::@compat(Union{(@compat Void), AbstractMatrix, AbstractDataFrame}),
              mapping::Dict, elements::ElementOrFunctionOrLayers...)
```
The old fashioned (pre named arguments) version of plot.

This version takes an explicit mapping dictionary, mapping aesthetics symbols
to expressions or columns in the data frame.

### Args:
* data_source: Data to be bound to aesthetics.
* mapping: Dictionary of aesthetics symbols (e.g. :x, :y, :color) to
            names of columns in the data frame or other expressions.
*   elements: Geometries, statistics, etc.

### Returns:
A Plot object.
"""
function plot(data_source::@compat(Union{(@compat Void), AbstractMatrix, AbstractDataFrame}),
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
    datas = Array(Data, length(plot.layers))
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
    layer_stats = Array(Vector{StatisticElement}, length(plot.layers))
    for (i, layer) in enumerate(plot.layers)
        layer_stats[i] = isempty(layer.statistics) ?
            [default_statistic(layer.geom)] : layer.statistics
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

        if :x in layer_needed_aes && :y in layer_needed_aes
            if !(:x in layer_defined_aes)
                unshift!(layer_stats[i], Stat.x_enumerate)
            elseif !(:y in layer_defined_aes)
                unshift!(layer_stats[i], Stat.y_enumerate)
            end
        end
    end

    used_aesthetics = Set{Symbol}()
    for layer in plot.layers
        union!(used_aesthetics, element_aesthetics(layer.geom))
    end

    for stats in layer_stats
        for stat in stats
            union!(used_aesthetics, input_aesthetics(stat))
        end
    end

    mapped_aesthetics = Set(keys(plot.mapping))
    for layer in plot.layers
        union!(mapped_aesthetics, keys(layer.mapping))
    end

    defined_unused_aesthetics = setdiff(mapped_aesthetics, used_aesthetics)
    if !isempty(defined_unused_aesthetics)
        warn("The following aesthetics are mapped, but not used by any geometry:\n    ",
             join([string(a) for a in defined_unused_aesthetics], ", "))
    end

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

    for element in chain([(s, plot.theme) for s in plot.statistics],
                         [(l.geom, _theme(plot, l)) for l in plot.layers],
                         layer_stats_with_theme...)

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
        if !in(var, mapped_aesthetics)
            continue
        end

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

        if var_data == nothing
            continue
        end

        t = classify_data(var_data)
        if t == nothing

        end

        if scale_exists(t, var)
            scale = get_scale(t, var, plot.theme)
            scale_aes = Set(element_aesthetics(scale))
            for var in scale_aes
                scales[var] = scale
            end
        end
    end

    for var in unscaled_aesthetics
        if haskey(plot.mapping, var) || haskey(scales, var)
            continue
        end

        t = :categorical
        for data in chain(datas, subplot_datas)
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
        if !in(Guide.PanelBackground, explicit_guide_types)
            push!(guides, Guide.background())
        end

        if !in(Guide.ZoomSlider, explicit_guide_types)
            push!(guides, Guide.zoomslider())
        end

        if !in(Guide.XTicks, explicit_guide_types)
            push!(guides, Guide.xticks())
        end

        if !in(Guide.YTicks, explicit_guide_types)
            push!(guides, Guide.yticks())
        end
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
    layer_aess = Scale.apply_scales(Iterators.distinct(values(scales)),
                                    datas..., subplot_datas...)

    # set default labels
    for (i, layer) in enumerate(plot.layers)
        if layer_aess[i].color_key_title == nothing &&
           haskey(layer.mapping, :color) &&
           !isa(layer.mapping[:color], AbstractArray)
           layer_aess[i].color_key_title = string(layer.mapping[:color])
       end
    end

    if layer_aess[1].color_key_title == nothing &&
       haskey(plot.mapping, :color) && !isa(plot.mapping[:color], AbstractArray)
        layer_aess[1].color_key_title = string(plot.mapping[:color])
    end

    # IIa. Layer-wise statistics
    for (stats, aes) in zip(layer_stats, layer_aess)
        Stat.apply_statistics(stats, scales, coord, aes)
    end

    # IIb. Plot-wise Statistics
    plot_aes = concat(layer_aess...)
    statistics = collect(statistics)
    Stat.apply_statistics(statistics, scales, coord, plot_aes)

    # Add some default guides determined by defined aesthetics
    supress_colorkey = false
    for layer in plot.layers
        if isa(layer.geom, Geom.SubplotGeometry) &&
                haskey(layer.geom.guides, Guide.ColorKey)
            supress_colorkey = true
            break
        end
    end

    if !supress_colorkey &&
       !all([aes.color === nothing for aes in [plot_aes, layer_aess...]]) &&
       !in(Guide.ColorKey, explicit_guide_types) &&
       !in(Guide.ManualColorKey, explicit_guide_types)
        push!(guides, Guide.colorkey())
    end

    # build arrays of scaled aesthetics for layers within subplots
    layer_subplot_aess = Array(Vector{Aesthetics}, length(plot.layers))
    layer_subplot_datas = Array(Vector{Data}, length(plot.layers))
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
```
render(plot::Plot)
```
Render a plot based on the Plot object

### Args
*   plot: Plot to be rendered.

### Returns
A Compose context containing the rendered plot.
"""
function render(plot::Plot)
    (plot, coord, plot_aes,
     layer_aess, layer_stats, layer_subplot_aess, layer_subplot_datas,
     scales, guides) = render_prepare(plot)

    root_context = render_prepared(plot, coord, plot_aes, layer_aess,
                                   layer_stats, layer_subplot_aess,
                                   layer_subplot_datas,
                                   scales, guides)

    ctx =  pad_inner(root_context, plot.theme.plot_padding)

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
```
draw(backend::Compose.Backend, p::Plot)
```
A convenience version of Compose.draw without having to call render

### Args
* backend: The Compose.Backend object
* p: The Plot object
"""
function draw(backend::Compose.Backend, p::Plot)
    draw(backend, render(p))
end


# Convenience stacking functions
"""
```
vstack(ps::Plot...) = vstack(Context[render(p) for p in ps]...)
vstack(ps::Vector{Plot}) = vstack(Context[render(p) for p in ps]...)
vstack(p::Plot, c::Context) = vstack(render(p), c)
vstack(c::Context, p::Plot) = vstack(c, render(p))
```
Plots can be stacked vertically to allow more customization in regards to tick marks, axis labeling, and other plot details than what is available with subplot_grid
"""
vstack(ps::Plot...) = vstack(Context[render(p) for p in ps]...)
vstack(ps::Vector{Plot}) = vstack(Context[render(p) for p in ps]...)
vstack(p::Plot, c::Context) = vstack(render(p), c)
vstack(c::Context, p::Plot) = vstack(c, render(p))

"""
```
hstack(ps::Plot...) = hstack(Context[render(p) for p in ps]...)
hstack(ps::Vector{Plot}) = hstack(Context[render(p) for p in ps]...)
hstack(p::Plot, c::Context) = hstack(render(p), c)
hstack(c::Context, p::Plot) = hstack(c, render(p))
```
Plots can be stacked horizontally to allow more customization in regards to tick marks, axis labeling, and other plot details than what is available with subplot_grid
"""
hstack(ps::Plot...) = hstack(Context[render(p) for p in ps]...)
hstack(ps::Vector{Plot}) = hstack(Context[render(p) for p in ps]...)
hstack(p::Plot, c::Context) = hstack(render(p), c)
hstack(c::Context, p::Plot) = hstack(c, render(p))

gridstack(ps::Matrix{Plot}) = gridstack(map(render, ps))

# show functions for all supported compose backends.


@compat function show(io::IO, m::MIME"text/html", p::Plot)
    buf = IOBuffer()
    svg = SVGJS(buf, Compose.default_graphic_width,
                Compose.default_graphic_height, false)
    draw(svg, p)
    show(io, m, svg)
end


@compat function show(io::IO, m::MIME"image/svg+xml", p::Plot)
    buf = IOBuffer()
    svg = SVG(buf, Compose.default_graphic_width,
              Compose.default_graphic_height, false)
    draw(svg, p)
    show(io, m, svg)
end


try
    getfield(Compose, :Cairo) # throws if Cairo isn't being used
    global show
    @compat function show(io::IO, ::MIME"image/png", p::Plot)
        draw(PNG(io, Compose.default_graphic_width,
                 Compose.default_graphic_height), p)
    end
end

try
    getfield(Compose, :Cairo) # throws if Cairo isn't being used
    global show
    @compat function show(io::IO, ::MIME"application/postscript", p::Plot)
        draw(PS(io, Compose.default_graphic_width,
             Compose.default_graphic_height), p);
    end
end

@compat function show(io::IO, ::MIME"text/plain", p::Plot)
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

import Base.Multimedia: @try_display, xdisplayable
import Base.REPL: REPLDisplay

function display(p::Plot)
    displays = Base.Multimedia.displays
    for i = length(displays):-1:1
        m = default_mime()
        if xdisplayable(displays[i], m, p)
             @try_display return display(displays[i], m, p)
        end

        if xdisplayable(displays[i], p)
            @try_display return display(displays[i], p)
        end
    end
    invoke(display, Tuple{Any}, p)
end


function open_file(filename)
    if is_apple()
        run(`open $(filename)`)
    elseif is_linux() || is_bsd()
        run(`xdg-open $(filename)`)
    elseif is_windows()
        run(`$(ENV["COMSPEC"]) /c start $(filename)`)
    else
        warn("Showing plots is not supported on OS $(string(Compat.KERNEL))")
    end
end

# Fallback display method. When there isn't a better option, we write to a
# temporary file and try to open it.
function display(d::REPLDisplay, ::MIME"image/png", p::Plot)
    filename = string(tempname(), ".png")
    output = open(filename, "w")
    draw(PNG(output, Compose.default_graphic_width,
             Compose.default_graphic_height), p)
    close(output)
    open_file(filename)
end

function display(d::REPLDisplay, ::MIME"image/svg+xml", p::Plot)
    filename = string(tempname(), ".svg")
    output = open(filename, "w")
    draw(SVG(output, Compose.default_graphic_width,
             Compose.default_graphic_height), p)
    close(output)
    open_file(filename)
end

function display(d::REPLDisplay, ::MIME"text/html", p::Plot)
    filename = string(tempname(), ".html")
    output = open(filename, "w")

    plot_output = IOBuffer()
    draw(SVGJS(plot_output, Compose.default_graphic_width,
               Compose.default_graphic_height, false), p)
    plotsvg = takebuf_string(plot_output)

    write(output,
        """
        <!DOCTYPE html>
        <html>
          <head>
            <title>Gadfly Plot</title>
            <meta charset="utf-8">
          </head>
            <body>
            <script charset="utf-8">
                $(readstring(Compose.snapsvgjs))
            </script>
            <script charset="utf-8">
                $(readstring(gadflyjs))
            </script>

            $(plotsvg)
          </body>
        </html>
        """)
    close(output)
    open_file(filename)
end

function display(d::REPLDisplay, ::MIME"application/postscript", p::Plot)
    filename = string(tempname(), ".ps")
    output = open(filename, "w")
    draw(PS(output, Compose.default_graphic_width,
            Compose.default_graphic_height), p)
    close(output)
    open_file(filename)
end

function display(d::REPLDisplay, ::MIME"application/pdf", p::Plot)
    filename = string(tempname(), ".pdf")
    output = open(filename, "w")
    draw(PDF(output, Compose.default_graphic_width,
             Compose.default_graphic_height), p)
    close(output)
    open_file(filename)
end

# Display in Juno

import Juno: Juno, @render, media, Media, Hiccup

media(Plot, Media.Plot)

@render Juno.PlotPane p::Plot begin
    x, y = Juno.plotsize()
    set_default_plot_size(x*Gadfly.px, y*Gadfly.px)
    HTML(stringmime("text/html", p))
end

@render Juno.Editor p::Gadfly.Plot begin
    Juno.icon("graph")
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
        :z => Scale.z_func(),
        :y => Scale.y_func()
    ),

    :numerical => Dict{Symbol, Any}(
        :x           => Scale.x_continuous(),
        :xmin        => Scale.x_continuous(),
        :xmax        => Scale.x_continuous(),
        :xintercept       => Scale.x_continuous(),
        :xend  => Scale.x_continuous(),
        :yend  => Scale.y_continuous(),
        :y           => Scale.y_continuous(),
        :ymin        => Scale.y_continuous(),
        :ymax        => Scale.y_continuous(),
        :yintercept  => Scale.y_continuous(),
        :middle      => Scale.y_continuous(),
        :upper_fence => Scale.y_continuous(),
        :lower_fence => Scale.y_continuous(),
        :upper_hinge => Scale.y_continuous(),
        :lower_hinge => Scale.y_continuous(),
        :xgroup      => Scale.xgroup(),
        :ygroup      => Scale.ygroup(),
        :shape       => Scale.shape_discrete(),
        :group       => Scale.group_discrete(),
        :label       => Scale.label(),
        :size        => Scale.size_continuous()
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
        :group      => Scale.group_discrete(),
        :label      => Scale.label()
    )
)


function get_scale{t,var}(::Val{t}, ::Val{var}, theme::Theme)
    default_aes_scales[t][var]
end


function get_scale(t::Symbol, var::Symbol, theme::Theme)
    get_scale(Val{t}(), Val{var}(), theme)
end


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

typealias CategoricalType @compat(Union{AbstractString, Bool, Symbol})


function classify_data{N, T <: CategoricalType}(data::AbstractArray{T, N})
    :categorical
end

function classify_data{N, T <: Base.Callable}(data::AbstractArray{T, N})
    :functional
end

function classify_data{T <: Base.Callable}(data::T)
    :functional
end

function classify_data(data::AbstractArray{Any})
    for val in data
        if isa(val, CategoricalType)
            return :categorical
        end
    end
    :numerical
end

function classify_data(data::AbstractArray)
    :numerical
end

function classify_data(data::Distribution)
    :distribution
end

# Axis labels are taken whatever is mapped to these aesthetics, in order of
# preference.
const x_axis_label_aesthetics = [:x, :xmin, :xmax]
const y_axis_label_aesthetics = [:y, :ymin, :ymax]

include("precompile.jl")
_precompile_()

end # module Gadfly
