# Subplot geometries

abstract type SubplotGeometry <: Gadfly.GeometryElement end

# Adding elements to subplots in a generic way.

add_subplot_element(subplot::SubplotGeometry, arg::Base.Callable) =
        add_subplot_element(subplot, arg())
add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.Layer) = push!(subplot.layers, arg)

function add_subplot_element(subplot::SubplotGeometry, arg::Vector{Gadfly.Layer})
    for layer in arg
        push!(subplot.layers, layer)
    end
end

function add_subplot_element(p::SubplotGeometry, arg::Gadfly.GeometryElement)
    if !isempty(p.layers) && isa(p.layers[end].geom, Geom.Nil)
        p.layers[end].geom = arg
    else
        layer = Layer()
        layer.geom = arg
        push!(p.layers, layer)
    end
end

add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.StatisticElement) =
        push!(subplot.statistics, arg)

function add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.ScaleElement)
    push!(subplot.scales, arg)
    if (isa(arg, Scale.ContinuousColorScale) ||
        isa(arg, Scale.DiscreteColorScale)) && !haskey(subplot.guides, Guide.ColorKey)
        subplot.guides[Guide.ColorKey] = Guide.colorkey()
    end
end

add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.GuideElement) =
        subplot.guides[typeof(arg)] = arg
add_subplot_element(subplot::SubplotGeometry, arg::Type{T}) where {T <: Gadfly.Element} =
        add_subplot_element(subplot, arg())
add_subplot_element(subplot::SubplotGeometry, coord::Gadfly.CoordinateElement) =
        subplot.coord = coord
add_subplot_element(subplot::SubplotGeometry, arg) =
        error("Subplots do not support elements of type $(typeof(arg))")

mutable struct SubplotGrid <: SubplotGeometry
    layers::Vector{Gadfly.Layer}
    statistics::Vector{Gadfly.StatisticElement}
    scales::Vector{Gadfly.ScaleElement}
    guides::Dict{Type, Gadfly.GuideElement}
    coord::Gadfly.CoordinateElement
    free_x_axis::Bool
    free_y_axis::Bool
end

# Current plot has no way of passing existing aesthetics. It always produces
# these using scales.
function SubplotGrid(elements::Gadfly.ElementOrFunctionOrLayers...;
                     free_x_axis=false, free_y_axis=false)
    subplot = SubplotGrid(Gadfly.Layer[], Gadfly.ScaleElement[], Gadfly.StatisticElement[],
                  Dict{Type, Gadfly.GuideElement}(), Coord.cartesian(),
                  free_x_axis, free_y_axis)

    for element in elements
        add_subplot_element(subplot, element)
    end

    # TODO: Handle default guides and statistics
    subplot
end

layers(geom::SubplotGrid) = geom.layers

"""
    Geom.subplot_grid[(elements...)]

Draw multiple subplots in a grid organized by one or two categorial vectors.

# Optional Aesthetics
- `xgroup`, `ygroup`: Arrange subplots on the X and Y axes, respectively, by categorial data.
- `free_x_axis`, `free_y_axis`: Whether the X and Y axis scales, respectively,
  can differ across the subplots. Defaults to `false`. If `true`, scales are
  set appropriately for individual subplots.

One or both of `xgroup` or `ygroup` must be bound. If only one, a single column
or row of subplots is drawn, if both, a grid.

# Arguments

Unlike most geometries, [`Geom.subplot_grid`](@ref) is typically passed one or more
parameters. The constructor works for the most part like the `layer` function.
Arbitrary plot elements may be passed, while aesthetic bindings are inherited
from the parent plot.
"""
const subplot_grid = SubplotGrid

function element_aesthetics(geom::SubplotGrid)
    vars = [:xgroup, :ygroup]
    for layer in geom.layers
        append!(vars, element_aesthetics(layer.geom))
    end
    vars
end

function default_scales(geom::SubplotGrid)
    scales = Gadfly.ScaleElement[]
    for stat in geom.statistics
        append!(scales, default_scales(stat))
    end

    for layer in geom.layers
        append!(scales, default_scales(layer.geom))
        append!(scales, default_scales(default_statistic(layer.geom)))
    end

    return scales
end

element_coordinate_type(::SubplotGrid) = Gadfly.Coord.subplot_grid

default_statistic(geom::SubplotGrid) = isempty(geom.statistics) ?
        [default_statistic(l.geom) for l in geom.layers] : geom.statistics


# Render a subplot grid geometry, which consists of rendering and arranging
# many smaller plots.
function render(geom::SubplotGrid, theme::Gadfly.Theme,
                superplot_aes::Gadfly.Aesthetics,
                subplot_layer_aess::Vector{Gadfly.Aesthetics},
                subplot_layer_datas::Vector{Gadfly.Data},
                scales::Dict{Symbol, Gadfly.ScaleElement})

    # inherit aesthetics from the plot when needed but not provided
    for (layer, layer_aes) in zip(geom.layers, subplot_layer_aess)
        inherited_aes = element_aesthetics(layer.geom)
        push!(inherited_aes, :xgroup, :ygroup)
        for var in inherited_aes
            if getfield(layer_aes, var) === nothing
                setfield!(layer_aes, var, getfield(superplot_aes, var))
            end
        end
    end
 # z
    for (layer_data, layer_aes) in zip(subplot_layer_datas, subplot_layer_aess)
        z = getfield(layer_data, :z)
        (z != nothing) && setfield!(layer_aes, :z, z)
    end

    # work out the grid size
    m = 1
    n = 1
    for layer_aes in subplot_layer_aess
        if layer_aes.xgroup != nothing
            m = max(m, maximum(layer_aes.xgroup))
        end
        if layer_aes.ygroup != nothing
            n = max(n, maximum(layer_aes.ygroup))
        end
    end

    layer_aes_grid = Array{Matrix{Gadfly.Aesthetics}}(undef, length(geom.layers))
    for (i, (layer, aes)) in enumerate(zip(geom.layers, subplot_layer_aess))
        layer_aes_grid[i] = Gadfly.by_xy_group(aes, aes.xgroup, aes.ygroup, m, n)
    end

    layer_data_grid = Array{Matrix{Gadfly.Data}}(undef, length(geom.layers))
    for (i, (layer, data, aes)) in enumerate(zip(geom.layers, subplot_layer_datas,
                                                 subplot_layer_aess))
        layer_data_grid[i] = Gadfly.by_xy_group(data, aes.xgroup, aes.ygroup, m, n)
    end

    coord = geom.coord
    plot_stats = Gadfly.StatisticElement[stat for stat in geom.statistics]
    layer_stats = [isempty(layer.statistics) ?
            Gadfly.StatisticElement[Geom.default_statistic(layer.geom)] : layer.statistics
                for layer in geom.layers]

    for i in 1:n, j in 1:m
        Scale.apply_scales(geom.scales,
                           Gadfly.Aesthetics[layer_aes_grid[k][i, j]
                                             for k in 1:length(geom.layers)],
                           Gadfly.Data[layer_data_grid[k][i, j]
                                       for k in 1:length(geom.layers)]...)

        for (k, stats) in enumerate(layer_stats)
            Stat.apply_statistics(stats, scales, coord, layer_aes_grid[k][i, j])
        end
    end

    # apply geom-wide statistics
    geom_aes = Gadfly.concat([layer_aes_grid[k][i,j]
                              for i in 1:n, j in 1:m, k in 1:length(geom.layers)]...)
    geom_stats = Gadfly.StatisticElement[]

    has_stat_xticks = false
    has_stat_yticks = false
    for guide in values(geom.guides)
        stat = default_statistic(guide)
        if !isa(stat, Gadfly.Stat.identity)
            if isa(stat, Gadfly.Stat.TickStatistic)
                if stat.axis == "x"
                    has_stat_xticks = true
                elseif stat.axis == "y"
                    has_stat_yticks = true
                end
            end
            push!(geom_stats, stat)
        end
    end

    !geom.free_x_axis && !has_stat_xticks && push!(geom_stats, Stat.xticks())
    !geom.free_y_axis && !has_stat_yticks && push!(geom_stats, Stat.yticks())

    Stat.apply_statistics(geom_stats, scales, coord, geom_aes)
    aes_grid = [geom_aes for i in 1:n, j in 1:m]

    # if either axis is on a free scale, we need to apply row/column-wise
    # tick statistics.
    if geom.free_x_axis
        for j in 1:m
            col_aes = Gadfly.concat([layer_aes_grid[k][i, j]
                                     for i in 1:n, k in 1:length(geom.layers)]...)
            Gadfly.inherit!(col_aes, geom_aes)
            Stat.apply_statistic(Stat.xticks(), scales, coord, col_aes)

            aes_grid[:, j] .= [col_aes]
        end
    end

    if geom.free_y_axis
        for i in 1:n
            row_aes = Gadfly.concat([layer_aes_grid[k][i, j]
                                     for j in 1:m, k in 1:length(geom.layers)]...)
            Gadfly.inherit!(row_aes, geom_aes)
            Stat.apply_statistic(Stat.yticks(), scales, coord, row_aes)

            for j in 1:m
                aes_grid[i, j] = Gadfly.inherit(row_aes, aes_grid[i, j])
            end
        end
    end

    for k in length(geom.layers), i in 1:n, j in 1:m
        Gadfly.inherit!(layer_aes_grid[k][i, j], aes_grid[i, j])
    end

    # TODO: this assumes a rather ridged layout

    hascolorkey = haskey(geom.guides, Guide.ColorKey)

    if hascolorkey
        xprop = [(isodd(j) ? 1.0 : NaN) for j in 3:2*m+2]
        tbl = table(n + 2, 2*m + 2, 1:n, 3:2*m+2,
                    x_prop=xprop, y_prop=ones(n),
                    fixed_configs=Any[
                        [(i, 1) for i in 1:n],
                        [(i, 2) for i in 1:n],
                        [(n+1, j) for j in 3:2:m+2],
                        [(n+2, j) for j in 3:2:m+2]])
    else
        tbl = table(n + 2, m + 2, 1:n, 3:m+2,
                    x_prop=ones(m), y_prop=ones(n),
                    fixed_configs=Any[
                        [(i, 1) for i in 1:n],
                        [(i, 2) for i in 1:n],
                        [(n+1, j) for j in 3:m+2],
                        [(n+2, j) for j in 3:m+2]])
    end

    xtitle = "x"
    for v in [:x, :xmin, :xmax]
        if haskey(superplot_aes.titles, v)
            xtitle = superplot_aes.titles[v]
            break
        end
    end

    ytitle = "y"
    for v in [:y, :ymin, :ymax]
        if haskey(superplot_aes.titles, v)
            ytitle = superplot_aes.titles[v]
            break
        end
    end

    xlabels = superplot_aes.xgroup_label(1:m)
    ylabels = superplot_aes.ygroup_label(1:n)
    subplot_padding = 2mm

    # This assumes non of the layers themselves are subplot geometries
    layer_subplot_aess = Vector{Gadfly.Aesthetics}[Array{Gadfly.Aesthetics}(undef, 0)
                                                   for _ in 1:length(geom.layers)]
    layer_subplot_datas = Vector{Gadfly.Data}[Array{Gadfly.Data}(undef, 0)
                                                   for _ in 1:length(geom.layers)]

    for i in 1:n, j in 1:m
        p = Plot()
        p.theme = theme
        p.layers = geom.layers
        guides = Gadfly.GuideElement[]

        for guide in values(geom.guides)
            if typeof(guide) in [Guide.XTicks, Guide.YTicks, Guide.XLabel, Guide.YLabel]
                continue
            end
            push!(guides, guide)
        end

        p.scales = collect(ScaleElement, values(scales))

        # default guides
        push!(guides, Guide.background())

        if i == n
            push!(guides, get(geom.guides, Guide.XTicks, Guide.xticks()))

            if superplot_aes.xgroup !== nothing
                push!(guides, get(geom.guides, Guide.XLabel, Guide.xlabel(xlabels[j])))
            end
        else
            push!(guides, Guide.xticks(label=false))
        end

        joff = 0
        if j == 1
            joff += 1
            push!(guides, get(geom.guides, Guide.YTicks, Guide.yticks()))
            if superplot_aes.ygroup !== nothing
                joff += 1
                push!(guides, get(geom.guides, Guide.YLabel, Guide.ylabel(ylabels[i])))
            end
        else
            push!(guides, Guide.yticks(label=false))
        end

        subtbl = Gadfly.render_prepared(
                            p, Gadfly.Coord.cartesian(),
                            aes_grid[i, j],
                            Gadfly.Aesthetics[layer_aes_grid[k][i, j]
                                              for k in 1:length(geom.layers)],
                            layer_stats,
                            layer_subplot_aess,
                            layer_subplot_datas,
                            scales,
                            guides,
                            table_only=true)

        # copy over the correct units, since we are reparenting the children
        for u in 1:size(subtbl, 1), v in 1:size(subtbl, 2)
            for child in subtbl[u, v]
                if child.units===nothing
                    child.units = subtbl.units
                end
            end
        end

        # All of the below needs to be rewritten to take into account the
        # possibility that subplots will have their own external guides.
        # We could special case it.
        if hascolorkey
            tbl[i, 2 + 2*j - 1] = pad(subtbl[1, 1 + joff],
                                      j > 1 ? subplot_padding : 0mm,
                                      subplot_padding,
                                      subplot_padding,
                                      i < n ? subplot_padding : 0mm)
            tbl[i, 2 + 2*j] = subtbl[1, 2 + joff]
        else
            tbl[i, 2 + j] = pad(subtbl[1, 1 + joff],
                                j > 1 ? subplot_padding : 0mm,
                                subplot_padding,
                                subplot_padding,
                                i < n ? subplot_padding : 0mm)
        end

        # bottom guides
        if i == n
            for k in 2:size(subtbl, 1)
                tbl[i + k - 1, hascolorkey ? 2 + 2*j - 1 : 2 + j] =
                    pad(subtbl[k, 1 + joff],
                        j > 1 ? subplot_padding : 0mm,
                        subplot_padding,
                        0mm, 0mm)
            end
        end

        # left guides
        if j == 1
            for k in 1:(size(subtbl, 2)-1)
                tbl[i, k] =
                    pad(subtbl[1, k],
                        0mm, 0mm,
                        subplot_padding,
                        i < n ? subplot_padding : 0mm)
            end
        end
    end

    return compose!(context(), tbl)
end
