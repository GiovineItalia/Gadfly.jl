# Line geometry connects (x, y) coordinates with lines.

struct LineGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement

    # Do not reorder points along the x-axis.
    preserve_order::Bool

    order::Int

    tag::Symbol
end

function LineGeometry(default_statistic=Gadfly.Stat.identity();
                      preserve_order=false, order=2, tag=empty_tag)
    LineGeometry(default_statistic, preserve_order, order, tag)
end

"""
    Geom.line[(; preserve_order=false, order=2)]

Draw a line connecting the `x` and `y` coordinates.  Optionally plot multiple
lines according to the `group` or `color` aesthetics.  `order` controls whether
the lines(s) are underneath or on top of other forms.

Set `preserve_order` to `:true` to *not* sort the points according to their
position along the x axis, or use the equivalent [`Geom.path`](@ref) alias.
"""
const line = LineGeometry

### why would one ever want to set preserve_order to false here
"""
    Geom.contours[(; levels=15, samples=150, preserve_order=true)]

Draw contour lines of the 2D function, matrix, or DataFrame in the `z`
aesthetic.  This geometry is equivalent to [`Geom.line`](@ref) with
[`Stat.contour`](@ref); see the latter for more information.
"""
function contour(; levels=15, samples=150, preserve_order=true)
    return LineGeometry(Gadfly.Stat.contour(levels=levels, samples=samples),
                                            preserve_order=preserve_order)
end

# Only allowing identity statistic in paths b/c I don't think any
# any of the others will work with `preserve_order=true` right now
"""
    Geom.path

Draw lines between `x` and `y` points in the order they are listed.  This
geometry is equivalent to [`Geom.line`](@ref) with `preserve_order=true`.
"""
path() = LineGeometry(preserve_order=true)

"""
    Geom.density2d[(; bandwidth=(-Inf,-Inf), levels=15)]

Draw a set of contours showing the density estimate of the `x` and `y`
aesthetics.  This geometry is equivalent to [`Geom.line`](@ref) with
[`Stat.density2d`](@ref); see the latter for more information.
"""
density2d(; bandwidth::Tuple{Real,Real}=(-Inf,-Inf), levels=15) =
    LineGeometry(Gadfly.Stat.density2d(bandwidth=bandwidth, levels=levels); preserve_order=true)

"""
    Geom.smooth[(; method:loess, smoothing=0.75)]

Plot a smooth function estimated from the line described by `x` and `y`
aesthetics.  Optionally group by `color` and plot multiple independent smooth
lines.  This geometry is equivalent to [`Geom.line`](@ref) with
[`Stat.smooth`](@ref); see the latter for more information.
"""
smooth(; method::Symbol=:loess, smoothing::Float64=0.75) =
    LineGeometry(Gadfly.Stat.smooth(method=method, smoothing=smoothing),
    order=5)

"""
    Geom.step[(; direction=:hv)]

Connect points described by the `x` and `y` aesthetics using a stepwise
function.  Optionally group by `color` or `group`.  This geometry is equivalent
to [`Geom.line`](@ref) with [`Stat.step`](@ref); see the latter for more
information.
"""
step(; direction::Symbol=:hv) = LineGeometry(Gadfly.Stat.step(direction=direction))

default_statistic(geom::LineGeometry) = geom.default_statistic

element_aesthetics(::LineGeometry) = [:x, :y, :color, :group]

function render(geom::LineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.line", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.line", aes,
                                          element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.color = discretize_make_ia(RGBA{Float32}[theme.default_color])
    aes = inherit(aes, default_aes)

    ctx = context(order=geom.order)
    XT, YT, CT = eltype(aes.x), eltype(aes.y), eltype(aes.color)
    XYT = Tuple{XT, YT}

    line_style = Gadfly.get_stroke_vector(theme.line_style)

    if aes.group != nothing
        GT = eltype(aes.group)

        if !geom.preserve_order
            p = sortperm(aes.x)
            aes_group = aes.group[p]
            aes_color = length(aes.color) > 1 ? aes.color[p] : aes.color
            aes_x = aes.x[p]
            aes_y = aes.y[p]
        else
            aes_group = copy(aes.group)
            aes_color = copy(aes.color)
            aes_x = copy(aes.x)
            aes_y = copy(aes.y)
        end

        # organize x, y pairs into lines
        if length(aes_group) > length(aes_color)
            p = sortperm(aes_group)
        elseif length(aes_color) > length(aes_group)
            p = sortperm(aes_color, lt=Gadfly.color_isless)
        else
            p = sortperm(collect((Tuple{GT, CT}),zip(aes_group, aes_color)),
                         lt=Gadfly.group_color_isless)
        end
        permute!(aes_group, p)
        permute!(aes_color, p)
        permute!(aes_x, p)
        permute!(aes_y, p)

        points = Vector{XYT}[]
        points_colors = CT[]
        points_groups = GT[]

        first_point = true
        for (i, (x, y, c, g)) in enumerate(zip(aes_x, aes_y, cycle(aes_color), aes_group))
            if !isconcrete(x) || !isconcrete(y)
                first_point = true
                continue
            end

            if i > 1 && (c != points_colors[end] || g != points_groups[end])
                first_point = true
            end

            if first_point
                push!(points, XYT[])
                push!(points_colors, c)
                push!(points_groups, g)
                first_point = false
            end

            push!(points[end], (x, y))
        end

        classes = [svg_color_class_from_label(aes.color_label([c])[1])
                   for (c, g) in zip(points_colors, points_groups)]

        ctx = compose!(ctx, (context(), Compose.line(points,geom.tag),
                        stroke(points_colors),
                        strokedash(line_style),
                        svgclass(classes)),
                      svgclass("geometry"))

    elseif length(aes.color) == 1 &&
            !(isa(aes.color, IndirectArray) && count(!ismissing, aes.color.values) > 1)
        T = (Tuple{eltype(aes.x), eltype(aes.y)})
        points = T[(x, y) for (x, y) in zip(aes.x, aes.y)]
        geom.preserve_order || sort!(points, by=first)
        ctx = compose!(ctx, (context(), Compose.line([points],geom.tag),
                       stroke(aes.color[1]),
                       strokedash(line_style)),
                       svgclass("geometry"))
    else
        if !geom.preserve_order
            p = sortperm(aes.x)
            aes_color = aes.color[p]
            aes_x = aes.x[p]
            aes_y = aes.y[p]
        else
            aes_color = copy(aes.color)
            aes_x = copy(aes.x)
            aes_y = copy(aes.y)
        end

        # organize x, y pairs into lines
        p = sortperm(aes_color, lt=Gadfly.color_isless)
        permute!(aes_color, p)
        permute!(aes_x, p)
        permute!(aes_y, p)

        points = Vector{XYT}[]
        points_colors = CT[]

        first_point = true
        for (i, (x, y, c)) in enumerate(zip(aes_x, aes_y, aes_color))
            if !isconcrete(x) || !isconcrete(y)
                first_point = true
                continue
            end

            if isempty(points_colors) || c != points_colors[end]
                first_point = true
            end

            if first_point
                push!(points, XYT[])
                push!(points_colors, c)
                first_point = false
            end

            push!(points[end], (x, y))
        end

        classes = [svg_color_class_from_label(aes.color_label([c])[1])
                   for c in points_colors]

        ctx = compose!(ctx, (context(), Compose.line(points,geom.tag),
                        stroke(points_colors),
                        strokedash(line_style),
                        svgclass(classes)),
                      svgclass("geometry"))
    end

    return compose!(ctx, fill(nothing), linewidth(theme.line_width))
end
