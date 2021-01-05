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
lines according to the `group`, `color` or `linestyle` aesthetics.  `order` controls whether
the lines(s) are underneath or on top of other forms.

Set `preserve_order=true` to *not* sort the points according to their
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
    Geom.density[(; bandwidth=-Inf)]

Draw a line showing the density estimate of the `x` aesthetic.
This geometry is equivalent to [`Geom.line`](@ref) with
[`Stat.density`](@ref); see the latter for more information.
"""
density(; bandwidth::Real=-Inf) =
    LineGeometry(Gadfly.Stat.density(bandwidth=bandwidth))

"""
    Geom.density2d[(; bandwidth=(-Inf,-Inf), levels=15)]

Draw a set of contours showing the density estimate of the `x` and `y`
aesthetics.  If grouped by `color`, then contour lines are mapped to `linestyle`.
This geometry is equivalent to [`Geom.line`](@ref) with
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

element_aesthetics(::LineGeometry) = [:x, :y, :color, :group, :linestyle]





function Gadfly.Geom.render(geom::LineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.line", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.line", aes, :x, :y)


    default_aes = Gadfly.Aesthetics()
    default_aes.group = IndirectArray([1])
    default_aes.color = [theme.default_color]
    default_aes.linestyle = theme.line_style[1:1]
    aes = inherit(aes, default_aes)

    # Render lines, using multivariate groupings:
    XT, YT = eltype(aes.x), eltype(aes.y)
    GT, CT, LST = Int, eltype(aes.color), eltype(aes.linestyle)
    groups = collect(Tuple{GT, CT, LST}, Compose.cyclezip(aes.group, aes.color, aes.linestyle))
    ugroups = unique(groups)
    nugroups = length(ugroups)
    # Recycle groups
    (1 .< length(groups) .< length(aes.x))  && (groups = [b for (a, b) in zip(aes.x, cycle(groups))])
    
    # Point order
    aes_x, aes_y, zgroups  = if !geom.preserve_order
        p = sortperm(aes.x)
        aes.x[p], aes.y[p], (nugroups==1 ? ugroups : groups[p])
    else
        aes.x, aes.y, (nugroups==1 ? ugroups : groups)
    end

    gs = Vector{GT}(undef, nugroups)
    cs = Vector{CT}(undef, nugroups)
    lss = Vector{LST}(undef, nugroups)
    lines = Vector{Vector{Tuple{XT,YT}}}(undef, nugroups)
    linestyle_palette_length = length(theme.line_style)
    if nugroups==1
        gs[1], cs[1], lss[1] = zgroups[1]
        lines[1] = collect(Tuple{XT, YT}, zip(aes_x, aes_y))
    elseif nugroups>1
        for (k,g) in enumerate(ugroups)
            i = zgroups.==[g]
            gs[k], cs[k], lss[k] = g
            lines[k] = collect(Tuple{XT,YT}, zip(aes_x[i], aes_y[i]))
        end
    end
    
    linestyles = Gadfly.get_stroke_vector.(LST<:Int ?
         theme.line_style[mod1.(lss, linestyle_palette_length)] : lss)
    
    classes = svg_color_class_from_label.(aes.color_label(cs))
    ctx = context(order=geom.order)
    ctx = compose!(ctx, (context(), Compose.line(lines, geom.tag),
            stroke(cs), strokedash(linestyles),
            svgclass(classes)), svgclass("geometry"))
    
    return compose!(ctx, fill(nothing), linewidth(theme.line_width))
end
