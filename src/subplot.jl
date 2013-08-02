
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

    # Current plot has no way of passing existing aesthetics. It always produces
    # these using scales.
    function SubplotGrid(elements::Gadfly.ElementOrFunction...)
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
                aes::Gadfly.Aesthetics)
    if aes.x_group === nothing && aes.y_group === nothing
        error("Geom.subplot_grid requires \"x_group\" and/or \"y_group\" to be bound.")
    end

    aes_grid = Gadfly.aes_by_xy_group(aes)
    n, m = size(aes_grid)

    guide_dict = Dict{Type, Gadfly.GuideElement}()
    for guide in geom.guides
        guide_dict[typeof(guide)] = guide
    end

    # default guides
    guide_dict[Guide.background] = Guide.background()

    layer_stats = Gadfly.StatisticElement[typeof(layer.statistic) == Stat.nil ?
                       Geom.default_statistic(layer.geom) : layer.statistic
                   for layer in geom.layers]

    canvas_grid = Array(Canvas, n, m)
    for i in 1:n, j in 1:m
        p = Plot()
        p.theme = theme
        for layer in geom.layers
            plot_layer = Gadfly.Layer()
            plot_layer.statistic = layer.statistic
            plot_layer.geom = layer.geom
            push!(p.layers, plot_layer)
        end
        aess = fill(aes_grid[i,j], length(geom.layers))

        canvas_grid[i, j] =
            Gadfly.render_prepared(
                            p, aess,
                            layer_stats,
                            Dict{Symbol, Gadfly.ScaleElement}(),
                            geom.statistics,
                            guide_dict)
    end

    gridstack(canvas_grid, 0w, 0h)
end


