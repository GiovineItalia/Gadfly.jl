
# Subplot geometries


abstract SubplotGeometry <: Gadfly.GeometryElement


# Adding elements to subplots in a generic way.

function add_subplot_element(subplot::SubplotGeometry, arg::Base.Callable)
    add_subplot_element(subplot, arg())
end


function add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.Layer)
    push!(subplot.layers, arg)
end


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


function add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.StatisticElement)
    push!(subplot.statistics, arg)
end


function add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.ScaleElement)
    push!(subplot.scales, arg)
    if (isa(arg, Scale.ContinuousColorScale) ||
        isa(arg, Scale.DiscreteColorScale)) && !haskey(subplot.guides, Guide.ColorKey)
        subplot.guides[Guide.ColorKey] = Guide.colorkey()
    end
end


function add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.GuideElement)
    subplot.guides[typeof(arg)] = arg
end


function add_subplot_element{T <: Gadfly.Element}(subplot::SubplotGeometry,
                                                  arg::Type{T})
    add_subplot_element(subplot, arg())
end


function add_subplot_element(subplot::SubplotGeometry, arg)
    error("Subplots do not support elements of type $(typeof(arg))")
end


immutable SubplotGrid <: SubplotGeometry
    layers::Vector{Gadfly.Layer}
    statistics::Vector{Gadfly.StatisticElement}
    scales::Vector{Gadfly.ScaleElement}
    guides::Dict{Type, Gadfly.GuideElement}
    free_x_axis::Bool
    free_y_axis::Bool

    # Current plot has no way of passing existing aesthetics. It always produces
    # these using scales.
    function SubplotGrid(elements::Gadfly.ElementOrFunctionOrLayers...;
                         free_x_axis=false, free_y_axis=false)
        subplot = new(Gadfly.Layer[], Gadfly.ScaleElement[], Gadfly.StatisticElement[],
                      Dict{Type, Gadfly.GuideElement}(), free_x_axis, free_y_axis)

        for element in elements
            add_subplot_element(subplot, element)
        end

        # TODO: Handle default guides and statistics
        subplot
    end
end


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


function element_coordinate_type(::SubplotGrid)
    return Gadfly.Coord.subplot_grid
end


# Render a subplot grid geometry, which consists of rendering and arranging
# many smaller plots.
function render(geom::SubplotGrid, theme::Gadfly.Theme,
                superplot_aes::Gadfly.Aesthetics,
                superplot_data::Gadfly.Data,
                scales::Dict{Symbol, ScaleElement})
    if superplot_aes.xgroup === nothing && superplot_aes.ygroup === nothing
        error("Geom.subplot_grid requires \"xgroup\" and/or \"ygroup\" to be bound.")
    end

    # partition the each aesthetic into a matrix of aesthetics
    aes_grid = Gadfly.by_xy_group(superplot_aes, superplot_aes.xgroup,
                                  superplot_aes.ygroup)
    n, m = size(aes_grid)

    data_grid = Gadfly.by_xy_group(superplot_data, superplot_aes.xgroup,
                                   superplot_aes.ygroup)

    coord = Coord.cartesian()
    plot_stats = Gadfly.StatisticElement[stat for stat in geom.statistics]
    layer_stats = Gadfly.StatisticElement[typeof(layer.statistic) == Stat.nil ?
                       Geom.default_statistic(layer.geom) : layer.statistic
                   for layer in geom.layers]

    layer_aes_grid = Array(Vector{Gadfly.Aesthetics}, n, m)
    layer_data_grid = Array(Vector{Gadfly.Data}, n, m)

    for i in 1:n, j in 1:m
        layer_aes = Gadfly.Aesthetics[copy(aes_grid[i, j])
                                      for _ in 1:length(geom.layers)]
        layer_data_grid[i, j] = [data_grid[i, j] for _ in 1:length(geom.layers)]
        Scale.apply_scales(geom.scales, layer_aes,
                           layer_data_grid[i, j]...)


        for (layer_stat, aes) in zip(layer_stats, layer_aes)
            Stat.apply_statistics(Gadfly.StatisticElement[layer_stat],
                                  scales, coord, aes)
        end
        layer_aes_grid[i, j] = layer_aes

        plot_aes = Gadfly.concat(layer_aes...)
        Stat.apply_statistics(plot_stats, scales, coord, plot_aes)
        aes_grid[i, j] = plot_aes
    end

    # apply geom-wide statistics
    geom_aes = Gadfly.concat(aes_grid...)
    geom_stats = Gadfly.StatisticElement[]

    has_stat_xticks = false
    has_stat_yticks = false
    for guide in values(geom.guides)
        stat = default_statistic(guide)
        if !isa(stat, Gadfly.Stat.identity)
            if isa(stat, Gadfly.Stat.TickStatistic)
                if stat.out_var == "x"
                    has_stat_xticks = true
                elseif stat.out_var == "y"
                    has_stat_yticks = true
                end
            end
            push!(geom_stats, stat)
        end
    end

    if !geom.free_x_axis && !has_stat_xticks
        push!(geom_stats, Stat.xticks())
    end

    if !geom.free_y_axis && !has_stat_yticks
        push!(geom_stats, Stat.yticks())
    end

    Stat.apply_statistics(geom_stats, scales, coord, geom_aes)

    # if either axis is on a free scale, we need to apply row/column-wise
    # tick statistics.
    if (geom.free_x_axis)
        for j in 1:m
            col_aes = Gadfly.concat([aes_grid[i, j] for i in 1:n]...)
            Stat.apply_statistic(Stat.xticks(), scales, coord, col_aes)
            for i in 1:n
                aes_grid[i, j] = Gadfly.concat(aes_grid[i, j], col_aes)
            end
        end
    end

    if (geom.free_y_axis)
        for i in 1:n
            row_aes = Gadfly.concat([aes_grid[i, j] for j in 1:m]...)
            row_aes.xgrid = nothing
            row_aes.xtick = nothing
            row_aes.xtickvisible = nothing
            row_aes.xtickscale = nothing

            Stat.apply_statistic(Stat.yticks(), scales, coord, row_aes)
            for j in 1:m
                aes_grid[i, j] = Gadfly.concat(aes_grid[i, j], row_aes)
            end
        end
    end

    for i in 1:n, j in 1:m
        Gadfly.inherit!(aes_grid[i, j], geom_aes)
    end

    # TODO: this assumes a rather ridged layout

    hascolorkey = haskey(geom.guides, Guide.ColorKey)

    if hascolorkey
        xprop = [(isodd(j) ? 1.0 : NaN) for j in 3:2*m+2]
        tbl = table(n + 2, 2*m + 2, 1:n, 3:2*m+2,
                    x_prop=xprop, y_prop=ones(n),
                    fixed_configs={
                        [(i, 1) for i in 1:n],
                        [(i, 2) for i in 1:n],
                        [(n+1, j) for j in 3:2:m+2],
                        [(n+2, j) for j in 3:2:m+2]})
    else
        tbl = table(n + 2, m + 2, 1:n, 3:m+2,
                    x_prop=ones(m), y_prop=ones(n),
                    fixed_configs={
                        [(i, 1) for i in 1:n],
                        [(i, 2) for i in 1:n],
                        [(n+1, j) for j in 3:m+2],
                        [(n+2, j) for j in 3:m+2]})
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

    xlabels = superplot_aes.xgroup_label(1.0:m)
    ylabels = superplot_aes.ygroup_label(1.0:n)
    subplot_padding = 2mm

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

            if !is(superplot_aes.xgroup, nothing)
                push!(guides, get(geom.guides, Guide.XLabel, Guide.xlabel(xlabels[j])))
            end
        else
            push!(guides, Guide.xticks(label=false))
        end

        joff = 0
        if j == 1
            joff += 1
            push!(guides, get(geom.guides, Guide.YTicks, Guide.yticks()))
            if !is(superplot_aes.ygroup, nothing)
                joff += 1
                push!(guides, get(geom.guides, Guide.YLabel, Guide.ylabel(ylabels[i])))
            end
        else
            push!(guides, Guide.yticks(label=false))
        end

        subtbl = Gadfly.render_prepared(
                            p, Gadfly.Coord.cartesian(),
                            aes_grid[i, j], layer_aes_grid[i, j],
                            layer_data_grid[i, j],
                            layer_stats,
                            scales,
                            guides,
                            table_only=true)

        # copy over the correct units, since we are reparenting the children
        for u in 1:size(subtbl, 1), v in 1:size(subtbl, 2)
            for child in subtbl[u, v]
                if child.units == Compose.nil_unit_box
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
                tbl[i + k - 1, hascolorkey ? 2 + 2*j - 1: 2 + j] =
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


