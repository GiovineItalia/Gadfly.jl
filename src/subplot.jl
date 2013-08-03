
# Subplot geometries


abstract SubplotGeometry <: Gadfly.GeometryElement


immutable SubplotLayer
    statistic::Gadfly.StatisticElement
    geom::Gadfly.GeometryElement

    function SubplotLayer(geom::Gadfly.GeometryElement=Geom.nil(),
                          statistic::Gadfly.StatisticElement=Stat.nil())
        new(statistic, geom)
    end
end


# Adding elements to subplots in a generic way.
function add_subplot_element(subplot::SubplotGeometry, arg::SubplotLayer)
    push!(subplot.layers, arg)
end


function add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.GeometryElement)
    push!(subplot.layers, SubplotLayer(arg))
end


function add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.StatisticElement)
    push!(subplot.statistics, arg)
end


function add_subplot_element(subplot::SubplotGeometry, arg::Gadfly.GuideElement)
    push!(subplot.guides, arg)
end


function add_subplot_element{T <: Gadfly.Element}(subplot::SubplotGeometry,
                                                  arg::Type{T})
    add_subplot_element(subplot, arg())
end


function add_subplot_element(subplot::SubplotGeometry, arg)
    error("Subplots do not support elements of type $(typeof(arg))")
end


immutable SubplotGrid <: SubplotGeometry
    layers::Vector{SubplotLayer}
    statistics::Vector{Gadfly.StatisticElement}
    guides::Vector{Gadfly.GuideElement}
    free_x_axis::Bool
    free_y_axis::Bool

    # Current plot has no way of passing existing aesthetics. It always produces
    # these using scales.
    function SubplotGrid(elements::Gadfly.ElementOrFunction...;
                         free_x_axis=false, free_y_axis=false)
        subplot = new(SubplotLayer[], Gadfly.StatisticElement[], Gadfly.GuideElement[])

        for element in elements
            add_subplot_element(subplot, element)
        end

        # TODO: Handle default guides and statistics
        subplot
    end
end


const subplot_grid = SubplotGrid


function element_aesthetics(geom::SubplotGrid)
    vars = [:x_group, :y_group]
    for layer in geom.layers
        append!(vars, element_aesthetics(layer.geom))
    end
    vars
end


# Render a subplot grid geometry, which consists of rendering and arranging
# many smaller plots.
function render(geom::SubplotGrid, theme::Gadfly.Theme,
                superplot_aes::Gadfly.Aesthetics)
    if superplot_aes.x_group === nothing && superplot_aes.y_group === nothing
        error("Geom.subplot_grid requires \"x_group\" and/or \"y_group\" to be bound.")
    end

    # partition the each aesthetic into a matrix of aesthetics
    aes_grid = Gadfly.aes_by_xy_group(superplot_aes)
    n, m = size(aes_grid)

    # if we want to share any information across subplots (i.e. axisi, tick
    # marks), we need to apply statistics on the joint aesthetics.
    geom_stats = Gadfly.StatisticElement[]
    if !geom.free_x_axis
        push!(geom_stats, Stat.x_ticks)
    end

    if !geom.free_y_axis
        push!(geom_stats, Stat.y_ticks)
    end

    coord = Coord.cartesian()
    scales = Dict{Symbol, Gadfly.ScaleElement}()
    plot_stats = Gadfly.StatisticElement[stat for stat in geom.statistics]
    layer_stats = Gadfly.StatisticElement[typeof(layer.statistic) == Stat.nil ?
                       Geom.default_statistic(layer.geom) : layer.statistic
                   for layer in geom.layers]

    layer_aes_grid = Array(Array{Gadfly.Aesthetics, 1}, n, m)
    for i in 1:n, j in 1:m
        layer_aes = fill(copy(aes_grid[i, j]), length(geom.layers))
        for (layer_stat, aes) in zip(layer_stats, layer_aes)
            Stat.apply_statistics(Gadfly.StatisticElement[layer_stat],
                                  scales, coord, aes)
        end

        plot_aes = cat(layer_aes...)
        Stat.apply_statistics(plot_stats, scales, coord, plot_aes)

        aes_grid[i, j] = plot_aes
        layer_aes_grid[i, j] = layer_aes
    end

    # apply geom-wide statistics
    geom_aes = cat(aes_grid...)
    Stat.apply_statistics(geom_stats, scales, coord, geom_aes)

    for i in 1:n, j in 1:m
        Gadfly.inherit!(aes_grid[i, j], geom_aes)
    end

    canvas_grid = Array(Canvas, n, m)

    xtitle = "x"
    for v in [:x, :x_min, :x_max]
        if haskey(superplot_aes.titles, v)
            xtitle = superplot_aes.titles[v]
            break
        end
    end

    ytitle = "y"
    for v in [:y, :y_min, :y_max]
        if haskey(superplot_aes.titles, v)
            ytitle = superplot_aes.titles[v]
            break
        end
    end

    for i in 1:n, j in 1:m
        p = Plot()
        p.theme = theme
        for layer in geom.layers
            plot_layer = Gadfly.Layer()
            plot_layer.statistic = layer.statistic
            plot_layer.geom = layer.geom
            push!(p.layers, plot_layer)
        end
        #aess = fill(aes_grid[i,j], length(geom.layers))
        guides = (Type => Gadfly.GuideElement)[typeof(guide) => guide
                                               for guide in geom.guides]

        # default guides
        guides[Guide.background] = Guide.background()

        if i == n && !is(superplot_aes.x_group, nothing)
            guides[Guide.x_ticks] = Guide.x_ticks()
        else
            guides[Guide.x_ticks] = Guide.x_ticks(false)
        end


        if j == 1 && !is(superplot_aes.y_group, nothing)
            guides[Guide.y_ticks] = Guide.y_ticks()
        else
            guides[Guide.y_ticks] = Guide.y_ticks(false)
        end

        if i == n && j == 1
            guides[Guide.x_label] = Guide.x_label(xtitle)
            guides[Guide.y_label] = Guide.y_label(ytitle)
        end

        canvas_grid[i, j] =
            Gadfly.render_prepared(
                            p, aes_grid[i, j], layer_aes_grid[i, j],
                            layer_stats,
                            Dict{Symbol, Gadfly.ScaleElement}(),
                            plot_stats,
                            guides,
                            preserve_plot_canvas_size=true)

        canvas_grid[i, j] = pad(canvas_grid[i, j], 2.5mm)
    end

    gridstack(canvas_grid, 0w, 0h, halign=hright)
end


