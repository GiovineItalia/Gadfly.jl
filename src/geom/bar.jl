

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

    tag::Symbol

    function BarGeometry(; position::Symbol=:stack,
                         orientation::Symbol=:vertical,
                         tag::Symbol=empty_tag)
        new(position, orientation, Gadfly.Stat.bar(position=position,
            orientation = orientation), tag)
    end

    function BarGeometry(position::Symbol, orientation::Symbol,
                         default_statistic::Gadfly.StatisticElement,
                         tag::Symbol)
        new(position, orientation, default_statistic, tag)
    end
end

const bar = BarGeometry

function histogram(; position=:stack, bincount=nothing,
                   minbincount=3, maxbincount=150,
                   orientation::Symbol=:vertical,
                   density::Bool=false,
                   tag::Symbol=empty_tag)
    return BarGeometry(
        position, orientation,
        Gadfly.Stat.histogram(bincount=bincount,
                              minbincount=minbincount,
                              maxbincount=maxbincount,
                              position=position,
                              orientation=orientation,
                              density=density),
        tag)
end


function element_aesthetics(::BarGeometry)
    [:x, :xmin, :xmax, :y, :ymin, :ymax, :color]
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
        XT = eltype(aes.x)
        xz = convert(XT, zero(XT))
        ctx = compose!(
            context(),
            rectangle([min(xz, x) for x in aes.x],
                      [ymin*cy + theme.bar_spacing/2 for ymin in aes.ymin],
                      abs(aes.x),
                      [(ymax - ymin)*cy - theme.bar_spacing
                       for (ymin, ymax) in zip(aes.ymin, aes.ymax)], geom.tag),
            svgclass("geometry"))
    else
        YT = eltype(aes.y)
        yz = convert(YT, zero(YT))
        ctx = compose!(
            context(),
            rectangle([xmin*cx + theme.bar_spacing/2 for xmin in aes.xmin],
                      [min(yz, y) for y in aes.y],
                      [(xmax - xmin)*cx - theme.bar_spacing
                       for (xmin, xmax) in zip(aes.xmin, aes.xmax)],
                      abs(aes.y), geom.tag),
            svgclass("geometry"))
    end

    compose!(ctx, fill(theme.default_color))
    if isa(theme.bar_highlight, Function)
        compose!(ctx, stroke(theme.bar_highlight(theme.default_color)))
    elseif isa(theme.bar_highlight, Color)
        compose!(ctx, stroke(theme.bar_highlight))
    else
        compose!(ctx, stroke(nothing))
    end
    return ctx
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

    ctx = context()
    if orientation == :horizontal
        stack_height_dict = Dict()
        T = eltype(aes.x)
        z = convert(T, zero(T))
        for y in aes.ymin
            stack_height_dict[y] = z
        end
        stack_height = zeros(eltype(aes.x), length(idxs))

        for (i, j) in enumerate(idxs)
            stack_height[i] = stack_height_dict[aes.ymin[j]]
            stack_height_dict[aes.ymin[j]] += aes.x[j]
        end

        compose!(
            ctx,
            rectangle(
                stack_height,
                [aes.ymin[i]*cy + theme.bar_spacing/2 for i in idxs],
                [aes.x[i] for i in idxs],
                [(aes.ymax[i] - aes.ymin[i])*cy - theme.bar_spacing for i in idxs], geom.tag))
    elseif orientation == :vertical
        stack_height_dict = Dict()
        T = eltype(aes.y)
        z = convert(T, zero(T))
        for x in aes.xmin
            stack_height_dict[x] = z
        end
        stack_height = zeros(eltype(aes.y), length(idxs))

        for (i, j) in enumerate(idxs)
            stack_height[i] = stack_height_dict[aes.xmin[j]]
            stack_height_dict[aes.xmin[j]] += aes.y[j]
        end

        compose!(
            ctx,
            rectangle(
                [aes.xmin[i]*cx + theme.bar_spacing/2 for i in idxs],
                stack_height,
                [(aes.xmax[i] - aes.xmin[i])*cx - theme.bar_spacing for i in idxs],
                [aes.y[i] for i in idxs], geom.tag))
    else
        error("Orientation must be :horizontal or :vertical")
    end

    cs = [aes.color[i] for i in idxs]
    compose!(ctx, fill(cs), svgclass("geometry"))
    if isa(theme.bar_highlight, Function)
        compose!(ctx, stroke([theme.bar_highlight(c) for c in cs]))
    elseif isa(theme.bar_highlight, Color)
        compose!(ctx, stroke(theme.bar_highlight))
    else
        compose!(ctx, stroke(nothing))
    end
    return ctx
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

    ctx = context()
    if orientation == :horizontal
        dodge_count = DefaultDict(() -> 0)
        for i in idxs
            dodge_count[aes.ymin[i]] += 1
        end

        dodge_height = Dict()
        dodge_pos_dict = DefaultDict(() -> 0cy)
        for i in idxs
            dodge_height[aes.ymin[i]] =
                ((aes.ymax[i] - aes.ymin[i]) / dodge_count[aes.ymin[i]]) * cy
            dodge_pos_dict[aes.ymin[i]] = aes.ymin[i]*cy
        end

        dodge_pos = Array(Measure, length(idxs))
        for (i, j) in enumerate(idxs)
            dodge_pos[i] = dodge_pos_dict[aes.ymin[j]] + theme.bar_spacing/2
            dodge_pos_dict[aes.ymin[j]] += dodge_height[aes.ymin[j]]
        end

        XT = eltype(aes.x)
        xz = convert(XT, zero(XT))

        aes_x = aes.x[idxs]
        compose!(
            ctx,
            rectangle(
                [min(xz, x) for x in aes_x],
                dodge_pos,
                abs(aes_x),
                [((aes.ymax[i] - aes.ymin[i])*cy - theme.bar_spacing) / dodge_count[aes.ymin[i]]
                 for i in idxs], geom.tag))
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

        YT = eltype(aes.y)
        yz = convert(YT, zero(YT))

        aes_y = aes.y[idxs]
        compose!(
            ctx,
            rectangle(
                dodge_pos,
                [min(yz, y) for y in aes_y],
                [((aes.xmax[i] - aes.xmin[i])*cx - theme.bar_spacing) / dodge_count[aes.xmin[i]]
                 for i in idxs],
                abs(aes_y), geom.tag))
    else
        error("Orientation must be :horizontal or :vertical")
    end

    cs = [aes.color[i] for i in idxs]
    compose!(ctx, fill(cs), svgclass("geometry"))
    if isa(theme.bar_highlight, Function)
        compose!(ctx, stroke([theme.bar_highlight(c) for c in cs]))
    elseif isa(theme.bar_highlight, Color)
        compose!(ctx, stroke(theme.bar_highlight))
    else
        compose!(ctx, stroke(nothing))
    end
    return ctx
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
        Gadfly.assert_aesthetics_defined("BarGeometry", aes, :ymin, :ymax, :x)
        Gadfly.assert_aesthetics_equal_length("BarGeometry", aes, :ymin, :ymax, :x)
        var = :y
        minvar = :ymin
        maxvar = :ymax
    else
        Gadfly.assert_aesthetics_defined("BarGeometry", aes, :xmin, :xmax, :y)
        Gadfly.assert_aesthetics_equal_length("BarGeometry", aes, :xmin, :xmax, :y)
        var = :x
        minvar = :xmin
        maxvar = :xmax
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
        linewidth(theme.highlight_width),
        svgattribute("shape-rendering", "crispEdges"))
end
