# Geometry for vectors/arrows/segments


struct SegmentGeometry <: Gadfly.GeometryElement
    default_statistic::Gadfly.StatisticElement
    arrow::Bool
    filled::Bool
    tag::Symbol 
end 
SegmentGeometry(default_statistic=Gadfly.Stat.identity(); arrow=false, filled=false, tag=empty_tag) = 
    SegmentGeometry(default_statistic, arrow, filled, tag) 

"""
    Geom.segment[(; arrow=false, filled=false)]

Draw line segments from `x`, `y` to `xend`, `yend`.  Optionally specify their
`color`.  If `arrow` is `true` a `Scale` object for both axes must be
provided.  If `filled` is `true` the arrows are drawn with a filled polygon,
otherwise with a stroked line.
"""
const segment = SegmentGeometry

# Leave this as a function, pending extra arguments e.g. arrow attributes
"""
    Geom.vector[(; filled=false)]

This geometry is equivalent to [`Geom.segment(arrow=true)`](@ref).
"""
vector(; filled::Bool=false) = SegmentGeometry(arrow=true, filled=filled)

"""
    Geom.hair[(; intercept=0.0, orientation=:vertical)]

Draw lines from `x`, `y` to y=`intercept` if `orientation` is `:vertical` or
x=`intercept` if `:horizontal`.  Optionally specify their `color`.  This geometry
is equivalent to [`Geom.segment`](@ref) with [`Stat.hair`](@ref).
"""
hair(; intercept=0.0, orientation=:vertical) =
    SegmentGeometry(Gadfly.Stat.hair(intercept, orientation))

"""
    Geom.vectorfield[(; smoothness=1.0, scale=1.0, samples=20, filled=false)]

Draw a gradient vector field of the 2D function or a matrix in the `z`
aesthetic.  This geometry is equivalent to [`Geom.segment`](@ref) with
[`Stat.vectorfield`](@ref); see the latter for more information.
"""
function vectorfield(;smoothness=1.0, scale=1.0, samples=20, filled::Bool=false)
    return SegmentGeometry(
        Gadfly.Stat.vectorfield(smoothness, scale, samples), 
        arrow=true, filled=filled )
end

default_statistic(geom::SegmentGeometry) = geom.default_statistic
element_aesthetics(::SegmentGeometry) = [:x, :y, :xend, :yend, :color] 


function render(geom::SegmentGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    
    Gadfly.assert_aesthetics_defined("Geom.segment", aes, :x, :y, :xend, :yend)

    function arrow(x::T, y::T, xmax::T, ymax::T, xyrange::Vector{T}) where T<:Real
        dx = xmax-x
        dy = ymax-y
        vl = 0.225*hypot(dy/xyrange[2], dx/xyrange[1])
        θ =  atan(dy/xyrange[2], dx/xyrange[1])
        ϕ = pi/15
        xr = -vl*xyrange[1]*[cos(θ+ϕ), cos(θ-ϕ)]
        yr = -vl*xyrange[2]*[sin(θ+ϕ), sin(θ-ϕ)]
        [ (xmax+xr[1],ymax+yr[1]), (xmax,ymax), (xmax+xr[2],ymax+yr[2]) ]
    end

    n = length(aes.x)
    default_aes = Gadfly.Aesthetics()  
    default_aes.color = fill(RGBA{Float32}(theme.default_color), n)

    aes = inherit(aes, default_aes) 

    line_style = Gadfly.get_stroke_vector(theme.line_style[1])

    # Geom.vector requires information about scales

    if geom.arrow
        check = [aes.xviewmin, aes.xviewmax, aes.yviewmin, aes.yviewmax ]
        if any( map(x -> x === nothing, check) )
            error("For Geom.vector, Scale minvalue and maxvalue must be manually provided for both axes")
        end
         xyrange = [aes.xviewmax-aes.xviewmin, aes.yviewmax-aes.yviewmin]

         arrows = [ arrow(x, y, xend, yend, xyrange)
                for (x, y, xend, yend) in zip(aes.x, aes.y, aes.xend, aes.yend) ]
    end
    
    segments = [ [(x,y), (xend,yend)]
        for (x, y, xend, yend) in zip(aes.x, aes.y, aes.xend, aes.yend) ]  
       
    classes = [svg_color_class_from_label( aes.color_label([c])[1] ) for c in aes.color ]
    
    ctx = context()

    compose!( ctx, (context(), Compose.line(segments, geom.tag),
                stroke(aes.color), linewidth(theme.line_width), 
                strokedash(line_style), svgclass( classes )),
              svgclass("geometry")  )
    if geom.arrow
        if geom.filled
            compose!(ctx, (context(), Compose.polygon(arrows), fill(aes.color), strokedash([])) )
        else
            compose!(ctx, (context(), Compose.line(arrows), stroke(aes.color), linewidth(theme.line_width), 
            strokedash([]))  )        
        end
    end


    return ctx
end
