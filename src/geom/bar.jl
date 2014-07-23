

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
    [:x, :xmin, :xmax, :y, :color]
end


function default_statistic(geom::BarGeometry)
    return geom.default_statistic
end


# Render a single color bar chart
function render_colorless_bar(geom::BarGeometry,
                              theme::Gadfly.Theme,
                              aes::Gadfly.Aesthetics,
                              orientation::Symbol)
    if orientation == :horizontal
        return compose!(
            context(),
            rectangle([0.0],
                      [ymin*cy + theme.bar_spacing/2 for ymin in aes.ymin],
                      aes.x,
                      [(ymax - ymin)*cy - theme.bar_spacing
                       for (ymin, ymax) in zip(aes.ymin, aes.ymax)]),
            svgclass("geometry"))
    else
        return compose!(
            context(),
            rectangle([xmin*cx + theme.bar_spacing/2 for xmin in aes.xmin],
                      [0.0],
                      [(xmax - xmin)*cx - theme.bar_spacing
                       for (xmin, xmax) in zip(aes.xmin, aes.xmax)],
                      aes.y),
            svgclass("geometry"))
    end
end


# Render a bar chart grouped by discrete colors and stacked.
function render_colorful_stacked_bar(geom::BarGeometry,
                                     theme::Gadfly.Theme,
                                     aes::Gadfly.Aesthetics,
                                     orientation::Symbol)
    # preserve factor orders of pooled data arrays
    if isa(aes.color, PooledDataArray)
        idxs = sortperm(aes.color.refs, rev=true)
    else
        idxs = 1:length(aes.color)
    end

    if orientation == :horizontal
        stack_height_dict = Dict()
        for y in aes.ymin
            stack_height_dict[y] = zero(eltype(aes.x))
        end
        stack_height = zeros(eltype(aes.x), length(idxs))

        for (i, j) in enumerate(idxs)
            stack_height[i] = stack_height_dict[aes.ymin[j]]
            stack_height_dict[aes.ymin[j]] += aes.x[j]
        end

        return compose!(
            context(),
            rectangle(
                stack_height,
                [aes.ymin[i]*cy + theme.bar_spacing/2 for i in idxs],
                [aes.x[i] for i in idxs],
                [(aes.ymax[i] - aes.ymin[i])*cy - theme.bar_spacing for i in idxs]),
            fill([aes.color[i] for i in idxs]),
            svgclass("geometry"))
    elseif orientation == :vertical
        stack_height_dict = Dict()
        for x in aes.xmin
            stack_height_dict[x] = zero(eltype(aes.y))
        end
        stack_height = zeros(eltype(aes.y), length(idxs))

        for (i, j) in enumerate(idxs)
            stack_height[i] = stack_height_dict[aes.xmin[j]]
            stack_height_dict[aes.xmin[j]] += aes.y[j]
        end

        return compose!(
            context(),
            rectangle(
                [aes.xmin[i]*cx + theme.bar_spacing/2 for i in idxs],
                stack_height,
                [(aes.xmax[i] - aes.xmin[i])*cx - theme.bar_spacing for i in idxs],
                [aes.y[i] for i in idxs]),
            fill([aes.color[i] for i in idxs]),
            svgclass("geometry"))
    else
        error("Orientation must be :horizontal or :vertical")
    end
end


# Render a bar chart grouped by discrete colors and stuck next to each other.
function render_colorful_dodged_bar(geom::BarGeometry,
                                    theme::Gadfly.Theme,
                                    aes::Gadfly.Aesthetics,
                                    orientation::Symbol)
    # preserve factor orders of pooled data arrays
    if isa(aes.color, PooledDataArray)
        idxs = sortperm(aes.color.refs, rev=true)
    else
        idxs = 1:length(aes.color)
    end

    if orientation == :horizontal
        dodge_count = DefaultDict(() -> 0)
        for i in idxs
            dodge_count[aes.ymin[i]] += 1
        end

        dodge_height = Dict()
        for i in idxs
            dodge_pos_dict[aes.ymin[j]] += aes.ymin[j]*cy
            dodge_height[aes.ymin[i]] =
                ((aes.ymax[i] - aes.ymin[i]) / dodge_count[aes.ymin[i]]) * cy
        end

        dodge_pos_dict = DefaultDict(() -> 0cy)
        dodge_pos = Array(Measure, length(idxs))
        for (i, j) in enumerate(idxs)
            dodge_pos[i] = dodge_pos_dict[aes.ymin[j]] + theme.bar_spacing/2
            dodge_pos_dict[aes.ymin[j]] += dodge_height[aes.ymin[j]]
        end

        return compose!(
            context(),
            rectangle(
                [0.0],
                dodge_pos,
                [0.0],
                [((aes.ymax[i] - aes.ymin[i])*cy - theme.bar_spacing) / dodge_count[aes.ymin[i]]
                 for i in idxs]),
            fill([aes.color[i] for i in idxs]),
            svgclass("geometry"))
    elseif orientation == :vertical
        dodge_count = DefaultDict(() -> 0)
        for i in idxs
            dodge_count[aes.xmin[i]] += 1
        end

        dodge_width = Dict()
        dodge_pos_dict = DefaultDict(() -> 0cx)
        for i in idxs
            dodge_width[aes.xmin[i]] =
                ((aes.xmax[i] - aes.xmin[i]) / dodge_count[aes.xmin[i]]) * cx
            dodge_pos_dict[aes.xmin[i]] = aes.xmin[i]*cx
        end

        dodge_pos = Array(Measure, length(idxs))
        for (i, j) in enumerate(idxs)
            dodge_pos[i] = dodge_pos_dict[aes.xmin[j]] + theme.bar_spacing/2
            dodge_pos_dict[aes.xmin[j]] += dodge_width[aes.xmin[j]]
        end

        return compose!(
            context(),
            rectangle(
                dodge_pos,
                [0.0],
                [((aes.xmax[i] - aes.xmin[i])*cx - theme.bar_spacing) / dodge_count[aes.xmin[i]]
                 for i in idxs],
                [aes.y[i] for i in idxs]),
            fill([aes.color[i] for i in idxs]),
            svgclass("geometry"))
    else
        error("Orientation must be :horizontal or :vertical")
    end
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
function render(geom::BarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics,
                scales::Dict{Symbol, ScaleElement})
    if geom.orientation == :horizontal
        if (is(aes.ymin, nothing) || is(aes.ymax, nothing)) && is(aes.y, nothing)
            error("Geom.bar required \"y\" to be bound or both \"y_min\" and \"y_max\".")
        end
        var = :y
        minvar = :ymin
        maxvar = :ymax
    else
        if (is(aes.xmin, nothing) || is(aes.xmax, nothing)) && is(aes.x, nothing)
            error("Geom.bar required \"x\" to be bound or both \"x_min\" and \"x_max\".")
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
        unique_count = length(Set(values))
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
        ctx = render_colorless_bar(geom, theme, aes, geom.orientation)
    elseif geom.position == :stack
        ctx = render_colorful_stacked_bar(geom, theme, aes, geom.orientation)
    elseif geom.position == :dodge
        ctx = render_colorful_dodged_bar(geom, theme, aes, geom.orientation)
    else
        error("$(geom.position) is not a valid position for the bar geometry.")
    end

    return compose!(
        context(),
        ctx,
        svgattribute("shape-rendering", "crispEdges"),
        fill(theme.default_color),
        stroke(nothing))
end


