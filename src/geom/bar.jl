# Bar geometry summarizes data as vertical bars.
struct BarGeometry <: Gadfly.GeometryElement
    position::Symbol  # :stack (default) or :dodge
    orientation::Symbol # :vertical (default) or :horizontal
    default_statistic::Gadfly.StatisticElement
    tag::Symbol
end
BarGeometry(; position=:stack, orientation=:vertical, tag=empty_tag) =
        BarGeometry(position, orientation, Gadfly.Stat.bar(position=position,
            orientation = orientation), tag)

"""

    Geom.bar[(; position, orientation)]

Draw bar plots. This geometry works on pre-summarized data such as counts. To
draw histograms from a series of observations, add [`Stat.histogram`](@ref) to the plot,
or use the convenient geometry [`Geom.histogram`](@ref).

# Aesthetics
- `y`: Height of each bar.
- `color` (optional): Group categorically by color.

Either

- `x`: Position of each bar.

Or

- `xmin`: Starting x positions for each bar.
- `xmax`: End x positions for each bar.

If `x` is given, a bar will be drawn at each x value, specifying both `xmin` and
`xmax` allows bars of variable width to be drawn.

# Arguments
- `position`: Either `:stack` or `:dodge`. If the `color` aesthetic is
    bound this determines how bars of different colors should be arranged:
    stacked on top of each other, or placed side by side.

- `orientation`: Either `:vertical` (default) or `:horizontal`. If
    `:horizontal`, then the required aesthetics are `y` or `ymin/ymax`.
"""
const bar = BarGeometry

"""
    Geom.histogram[(; position, orientation, bincount, minbincount, maxbincount, density)]

Draw histograms. An alias for [`Geom.bar`](@ref) with [`Stat.histogram`](@ref).

# Aesthetics
- `x`: Sample to draw histogram from.
- `color` (optional): Group categorically by color.

# Arguments
- `position`: Either `:stack` or `:dodge`. If the `color` aesthetic is
    bound this determines how bars of different colors should be arranged:
    stacked on top of each other, or placed side by side.
- `orientation`: Either `:vertical` (default) or `:horizontal`. If
    `:horizontal`, then the required aesthetic is `y` instead of `x`.
- `bincount`: Number of bins to use. If unspecified, an optimization method
    is used to determine a reasonable value.
- `minbincount`: Set a lower limit when automatically choosing a bin count.
- `maxbincount`: Set an upper limit when automatically choosing a bin count.
- `density`: If true, use density rather that counts.
"""
histogram(; position=:stack, bincount=nothing,
                   minbincount=3, maxbincount=150,
                   orientation::Symbol=:vertical,
                   density::Bool=false,
                   tag::Symbol=empty_tag) =
    BarGeometry(position, orientation,
        Gadfly.Stat.histogram(bincount=bincount,
                              minbincount=minbincount,
                              maxbincount=maxbincount,
                              position=position,
                              orientation=orientation,
                              density=density),
        tag)

element_aesthetics(geom::BarGeometry) = geom.orientation == :vertical ?
            [:xmin, :xmax, :y, :color] : [:ymin, :ymax, :x, :color]

default_statistic(geom::BarGeometry) = geom.default_statistic

# Render a single color bar chart
function render_bar(geom::BarGeometry,
                              theme::Gadfly.Theme,
                              aes::Gadfly.Aesthetics,
                              orientation::Symbol)
    if orientation == :horizontal
        XT = eltype(aes.x)
        xz = convert(XT, zero(XT))
        ctx = compose!(context(),
            rectangle([min(xz, x) for x in aes.x],
                      [ymin*cy - theme.bar_spacing/2 for ymin in aes.ymin],
                      abs.(aes.x),
                      [(ymax - ymin)*cy - theme.bar_spacing
                       for (ymin, ymax) in zip(aes.ymin, aes.ymax)], geom.tag),
            svgclass("geometry"))
    else
        YT = eltype(aes.y)
        yz = convert(YT, zero(YT))
        ctx = compose!(context(),
            rectangle([xmin*cx + theme.bar_spacing/2 for xmin in aes.xmin],
                      [min(yz, y) for y in aes.y],
                      [(xmax - xmin)*cx - theme.bar_spacing
                       for (xmin, xmax) in zip(aes.xmin, aes.xmax)],
                      abs.(aes.y), geom.tag),
            svgclass("geometry"))
    end

    cs = aes.color === nothing ? theme.default_color : aes.color
    compose!(ctx, fill(cs), svgclass("geometry"))
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
function render_stacked_bar(geom::BarGeometry,
                                     theme::Gadfly.Theme,
                                     aes::Gadfly.Aesthetics,
                                     orientation::Symbol)
    # preserve factor orders of pooled data arrays
    if isa(aes.color, IndirectArray)
        idxs = sortperm(aes.color.index, rev=true)
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
            if aes.x[j]>0
                stack_height[i] = stack_height_dict[aes.ymin[j]]
                stack_height_dict[aes.ymin[j]] += aes.x[j]
            else
                stack_height_dict[aes.ymin[j]] += aes.x[j]
                stack_height[i] = stack_height_dict[aes.ymin[j]]
            end
        end

        x0s = stack_height
        y0s = [aes.ymin[i]*cy + theme.bar_spacing/2 for i in idxs]
        widths = [abs(aes.x[i]) for i in idxs]
        heights = [(aes.ymax[i] - aes.ymin[i])*cy - theme.bar_spacing for i in idxs]
        compose!(ctx, rectangle(x0s, y0s, widths, heights, geom.tag))
    else
        stack_height_dict = Dict()
        T = eltype(aes.y)
        z = convert(T, zero(T))
        for x in aes.xmin
            stack_height_dict[x] = z
        end
        stack_height = zeros(eltype(aes.y), length(idxs))

        for (i, j) in enumerate(idxs)
            if aes.y[j]>0
                stack_height[i] = stack_height_dict[aes.xmin[j]]
                stack_height_dict[aes.xmin[j]] += aes.y[j]
            else
                stack_height_dict[aes.xmin[j]] += aes.y[j]
                stack_height[i] = stack_height_dict[aes.xmin[j]]
            end
        end

        x0s = [aes.xmin[i]*cx + theme.bar_spacing/2 for i in idxs]
        y0s = stack_height
        widths = [(aes.xmax[i] - aes.xmin[i])*cx - theme.bar_spacing for i in idxs]
        heights = [abs(aes.y[i]) for i in idxs]
        compose!(ctx, rectangle(x0s, y0s, widths, heights, geom.tag))
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
function render_dodged_bar(geom::BarGeometry,
                                    theme::Gadfly.Theme,
                                    aes::Gadfly.Aesthetics,
                                    orientation::Symbol)
    # preserve factor orders of pooled data arrays
    if isa(aes.color, IndirectArray)
        idxs = sortperm(aes.color.index, rev=true)
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

        dodge_pos = Array{Measure}(length(idxs))
        for (i, j) in enumerate(idxs)
            dodge_pos[i] = dodge_pos_dict[aes.ymin[j]] + theme.bar_spacing/2
            dodge_pos_dict[aes.ymin[j]] += dodge_height[aes.ymin[j]]
        end

        XT = eltype(aes.x)
        xz = convert(XT, zero(XT))

        aes_x = aes.x[idxs]
        compose!(ctx,
            rectangle([min(xz, x) for x in aes_x],
                dodge_pos,
                abs.(aes_x),
                [((aes.ymax[i] - aes.ymin[i])*cy - theme.bar_spacing) / dodge_count[aes.ymin[i]]
                 for i in idxs], geom.tag))
    else
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

        dodge_pos = Array{Measure}(length(idxs))
        for (i, j) in enumerate(idxs)
            dodge_pos[i] = dodge_pos_dict[aes.xmin[j]] + theme.bar_spacing/2
            dodge_pos_dict[aes.xmin[j]] += dodge_width[aes.xmin[j]]
        end

        YT = eltype(aes.y)
        yz = convert(YT, zero(YT))

        aes_y = aes.y[idxs]
        compose!(ctx,
            rectangle(dodge_pos,
                [min(yz, y) for y in aes_y],
                [((aes.xmax[i] - aes.xmin[i])*cx - theme.bar_spacing) / dodge_count[aes.xmin[i]]
                 for i in idxs],
                abs.(aes_y), geom.tag))
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
    elseif geom.orientation == :vertical
        Gadfly.assert_aesthetics_defined("BarGeometry", aes, :xmin, :xmax, :y)
        Gadfly.assert_aesthetics_equal_length("BarGeometry", aes, :xmin, :xmax, :y)
    else
        error("Orientation must be :horizontal or :vertical")
    end

    if aes.color === nothing
        ctx = render_bar(geom, theme, aes, geom.orientation)
    elseif geom.position == :stack
        if geom.orientation == :horizontal
            for y in unique(aes.ymin)
               signs = map(sign, aes.x[aes.ymin.==y])
               in(1, signs) && in(-1, signs) &&
                       error("x values must be of the same sign for each unique y value")
            end
        elseif geom.orientation == :vertical
            for x in unique(aes.xmin)
               signs = map(sign, aes.y[aes.xmin.==x])
               in(1, signs) && in(-1, signs) &&
                       error("y values must be of the same sign for each unique x value")
            end
        end
        ctx = render_stacked_bar(geom, theme, aes, geom.orientation)
    elseif geom.position == :dodge
        ctx = render_dodged_bar(geom, theme, aes, geom.orientation)
    else
        error("$(geom.position) is not a valid position for the bar geometry.")
    end

    return compose!(context(), ctx,
        linewidth(theme.highlight_width),
        svgattribute("shape-rendering", "crispEdges"))
end
