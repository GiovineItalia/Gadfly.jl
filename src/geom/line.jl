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

element_aesthetics(::LineGeometry) = [:x, :y, :color, :group, :linestyle]





function Gadfly.Geom.render(geom::LineGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.line", aes, :x, :y)
    Gadfly.assert_aesthetics_equal_length("Geom.line", aes, Geom.element_aesthetics(geom)...)

    default_aes = Gadfly.Aesthetics()
    default_aes.group = IndirectArray(fill(1,length(aes.x)))
    default_aes.color = fill(theme.default_color, length(aes.x))
    default_aes.linestyle = fill(1, length(aes.x))
    aes = Gadfly.inherit(aes, default_aes)
    
    # Point order:
    p = 1:length(aes.x)
    !geom.preserve_order && (p = sortperm(aes.x))
    aes_x, aes_y, aes_color, aes_g = aes.x[p], aes.y[p], aes.color[p], aes.group[p]
    aes_linestyle = aes.linestyle[p]
    
    # Find the aesthetic with the most levels:
    aesv = [aes_g, aes_color, aes_linestyle]
    i1 = argmax([length(unique(a)) for a in aesv])
    aes_maxlvls = aesv[i1]
  
    # Concrete values?:
    cf = Gadfly.isconcrete.(aes_x) .& Gadfly.isconcrete.(aes_y)
    fcf = .!cf
    ulvls =  unique(aes_maxlvls[fcf])
    aes_concrete = zeros(Int, length(cf))
    for g in ulvls    
        i = aes_maxlvls.==g
        aes_concrete[i] = cumsum(fcf[i])
    end
    
    aes_x, aes_y, aes_color, aes_g = aes_x[cf], aes_y[cf], aes_color[cf], aes_g[cf]
    aes_concrete, aes_linestyle = aes_concrete[cf], aes_linestyle[cf]
    
    # Render lines, using multivariate groupings:
    XT, YT, CT, GT, CNT = eltype(aes_x), eltype(aes_y), eltype(aes_color), eltype(aes_g), eltype(aes_concrete)
    LST = eltype(aes_linestyle)
    groups = collect((Tuple{GT, CT, LST, CNT}), zip(aes_g, aes_color, aes_linestyle, aes_concrete))
    ug = unique(groups)

    n = length(ug)
    lines = Vector{Vector{Tuple{XT,YT}}}(undef, n)
    line_colors = Vector{CT}(undef, n)
    line_styles = Vector{LST}(undef, n)
    linestyle_palette_length = length(theme.line_style)
    for (k,g) in enumerate(ug)
        i = groups.==[g]
        lines[k] = collect(Tuple{XT,YT}, zip(aes_x[i], aes_y[i]))
        line_colors[k] = first(aes_color[i])
        line_styles[k] = mod1(first(aes_linestyle[i]), linestyle_palette_length) 
    end
    
    linestyles =  Gadfly.get_stroke_vector.(theme.line_style[line_styles])
    classes = svg_color_class_from_label.(aes.color_label(line_colors))
    ctx = context(order=geom.order)
    ctx = compose!(ctx, (context(), Compose.line(lines, geom.tag),
                        stroke(line_colors),
                        strokedash(linestyles),
                        svgclass(classes)), svgclass("geometry")) 
    
    return compose!(ctx, fill(nothing), linewidth(theme.line_width))


end
