

# Bar geometry summarizes data as vertical bars.
immutable BarGeometry <: Gadfly.GeometryElement
    # How bars should be positioned if they are grouped by color.
    # Valid options are:
    #   :stack -> place bars on top of each other (default)
    #   :dodge -> place bar next to each other
    position::Symbol

    # :vertical or :horizontal
    orientation::Symbol

    default_statistic::Gadfly.StatisticElement

    function BarGeometry(default_statistic=Gadfly.Stat.identity();
                         position::Symbol=:stack, orientation::Symbol=:vertical)
        new(position, orientation, default_statistic)
    end
end


const bar = BarGeometry

function histogram(; position=:stack, bincount=nothing,
                   minbincount=3, maxbincount=150, orientation::Symbol=:vertical)
    BarGeometry(Gadfly.Stat.histogram(bincount=bincount,
                                      minbincount=minbincount,
                                      maxbincount=maxbincount,
                                      orientation=orientation),
                position=position,
                orientation=orientation)
end


function element_aesthetics(::BarGeometry)
    [:x, :y, :color]
end


function default_statistic(geom::BarGeometry)
    geom.default_statistic
end


# Render a single color bar chart
function render_colorless_bar(geom::BarGeometry,
                              theme::Gadfly.Theme,
                              aes::Gadfly.Aesthetics,
                              orientation::Symbol)
    bar_form = empty_form
    if orientation == :horizontal
        for (y_min, y_max, x) in zip(aes.ymin, aes.ymax, aes.x)
            geometry_id = Gadfly.unique_svg_id()
            bar_form = combine(bar_form,
                compose(rectangle(0.0, y_min*cy + theme.bar_spacing/2,
                                  x, (y_max - y_min)*cy - theme.bar_spacing),
                        svgid(geometry_id), svgclass("geometry")))
        end
    else
        for (x_min, x_max, y) in zip(aes.xmin, aes.xmax, aes.y)
            geometry_id = Gadfly.unique_svg_id()
            bar_form = combine(bar_form,
                compose(rectangle(x_min*cx + theme.bar_spacing/2, 0.0,
                                  (x_max - x_min)*cx - theme.bar_spacing, y),
                        svgid(geometry_id), svgclass("geometry")))
        end
    end
    bar_form
end


# Render a bar chart grouped by discrete colors and stacked.
function render_colorful_stacked_bar(geom::BarGeometry,
                                     theme::Gadfly.Theme,
                                     aes::Gadfly.Aesthetics,
                                     orientation::Symbol)
    bar_form = empty_form

    if orientation == :horizontal
        minvar = :ymin
    else
        minvar = :xmin
    end

    stack_height = Dict()
    for x_min in getfield(aes, minvar)
        stack_height[x_min] = 0.0
    end

    # preserve factor orders of pooled data arrays
    if isa(aes.color, PooledDataArray)
        idxs = sortperm(aes.color.refs, rev=true)
    else
        idxs = 1:length(aes.color)
    end

    if orientation == :horizontal
        for i in idxs
            y_min, y_max, x, c = aes.ymin[i], aes.ymax[i], aes.x[i], aes.color[i]
            geometry_id = Gadfly.unique_svg_id()
            bar_form = combine(bar_form,
                compose(rectangle(stack_height[y_min],
                                  y_min*cy + theme.bar_spacing/2,
                                  x, (y_max - y_min)*cy - theme.bar_spacing),
                        fill(c),
                        svgid(geometry_id),
                        svgclass("geometry")))
            stack_height[y_min] += x
        end
    else
        for i in idxs
            x_min, x_max, y, c = aes.xmin[i], aes.xmax[i], aes.y[i], aes.color[i]
            geometry_id = Gadfly.unique_svg_id()
            bar_form = combine(bar_form,
                compose(rectangle(x_min*cx + theme.bar_spacing/2,
                                  stack_height[x_min],
                                  (x_max - x_min)*cx - theme.bar_spacing, y),
                        fill(c),
                        svgid(geometry_id),
                        svgclass("geometry")))
            stack_height[x_min] += y
        end
    end
    bar_form
end


# Render a bar chart grouped by discrete colors and stuck next to each other.
function render_colorful_dodged_bar(geom::BarGeometry,
                                    theme::Gadfly.Theme,
                                    aes::Gadfly.Aesthetics,
                                    orientation::Symbol)
    if orientation == :horizontal
        minvar = :ymin
    else
        minvar = :xmin
    end
    bar_form = empty_form
    dodge_width = Dict()
    dodge_count = Dict()
    for x_min in getfield(aes, minvar)
        dodge_width[x_min] = 0.0cx
        dodge_count[x_min] = get(dodge_count, x_min, 0) + 1
    end

    # preserve factor orders of pooled data arrays
    if isa(aes.color, PooledDataArray)
        idxs = sortperm(aes.color.refs, rev=true)
    else
        idxs = 1:length(aes.color)
    end

    if orientation == :horizontal
        for i in idxs
            y_min, y_max, x, c = aes.ymin[i], aes.ymax[i], aes.x[i], aes.color[i]
            geometry_id = Gadfly.unique_svg_id()
            barwidth = ((y_max - y_min)*cy - theme.bar_spacing) / dodge_count[y_min]
            bar_form = combine(bar_form,
                compose(rectangle(0.0,
                                  y_min*cy + dodge_width[y_min] + theme.bar_spacing/2,
                                  0.0, barwidth),
                        fill(c),
                        svgid(geometry_id),
                        svgclass("geometry")))
            dodge_width[y_min] += barwidth
        end
    else
        for i in idxs
            x_min, x_max, y, c = aes.xmin[i], aes.xmax[i], aes.y[i], aes.color[i]
            geometry_id = Gadfly.unique_svg_id()
            barwidth = ((x_max - x_min)*cx - theme.bar_spacing) / dodge_count[x_min]
            bar_form = combine(bar_form,
                compose(rectangle(x_min*cx + dodge_width[x_min] + theme.bar_spacing/2,
                                  0.0, barwidth, y),
                        fill(c),
                        svgid(geometry_id),
                        svgclass("geometry")))
            dodge_width[x_min] += barwidth
        end
    end
    bar_form
end


# Render bar geometry.
#
# Args:
#   geom: bar geometry
#   theme: the plot's theme
#   aes: some aesthetics
#
# Returns
#   A compose form.
#
function render(geom::BarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    if geom.orientation == :horizontal
        Gadfly.assert_aesthetics_defined("Geom.bar", aes, :y)
        if (is(aes.xmin, nothing) || is(aes.xmax, nothing)) && is(aes.x, nothing)
            error("Geom.bar required \"x\" to be bound or both \"x_min\" and \"x_max\".")
        end
        var = :y
        minvar = :ymin
        maxvar = :ymax
    else
        Gadfly.assert_aesthetics_defined("Geom.bar", aes, :x)
        if (is(aes.ymin, nothing) || is(aes.ymax, nothing)) && is(aes.y, nothing)
            error("Geom.bar required \"y\" to be bound or both \"y_min\" and \"y_max\".")
        end
        var = :x
        minvar = :xmin
        maxvar = :xmax
    end

    if getfield(aes, minvar) === nothing
        aes2 = Gadfly.Aesthetics()
        values = getfield(aes, var)
        T = eltype(values)

        span = zero(T)
        unique_count = length(set(values))
        if unique_count > 1
            span = (maximum(values) - minimum(values)) / (unique_count - 1)
        end

        if span == zero(T)
            span = one(T)
        end

        T = promote_type(eltype(values), typeof(span/2))
        setfield!(aes2, minvar, Array(T, length(values)))
        setfield!(aes2, maxvar, Array(T, length(values)))

        for (i, x) in enumerate(values)
            getfield(aes2, minvar)[i] = x - span/2
            getfield(aes2, maxvar)[i] = x + span/2
        end
        aes = inherit(aes, aes2)
    end

    if aes.color === nothing
        form = render_colorless_bar(geom, theme, aes, geom.orientation)
    elseif geom.position == :stack
        form = render_colorful_stacked_bar(geom, theme, aes, geom.orientation)
    elseif geom.position == :dodge
        form = render_colorful_dodged_bar(geom, theme, aes, geom.orientation)
    else
        error("$(geom.position) is not a valid position for the bar geometry.")
    end

    compose(canvas(units_inherited=true),
            form,
            svgattribute("shape-rendering", "crispEdges"),
            fill(theme.default_color),
            stroke(nothing))
end


