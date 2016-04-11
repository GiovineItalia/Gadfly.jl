
abstract SegmentGeometry <: Gadfly.GeometryElement

# Geometry for vectors/arrows/segments
immutable SegmentGeom <: SegmentGeometry 
    
     arrow::Bool
     filled::Bool
     tag::Symbol 
 
    function SegmentGeom(;arrow=false, filled=false, tag=empty_tag) 
         new(arrow, filled, tag) 
     end 
end 

const segment = SegmentGeom

# Leave this as a function, pending extra arguments e.g. arrow attributes
function vector(;filled::Bool=false, tag::Symbol=empty_tag)
    return SegmentGeom(arrow=true, filled=filled, tag=tag)
end

 
function element_aesthetics(::SegmentGeom) 
    return [:x, :y, :xend, :yend, :color] 
end 


function Gadfly.render(geom::SegmentGeom, theme::Gadfly.Theme, aes::Gadfly.Aesthetics,
                subplot_layer_aess::@compat(Union{(@compat Void), Vector{Gadfly.Aesthetics}}),
                subplot_layer_datas::@compat(Union{(@compat Void), Vector{Gadfly.Data}}),
    scales::Dict{Symbol, Gadfly.ScaleElement})
    render(geom, theme, aes, scales)
end





function render(geom::SegmentGeom, theme::Gadfly.Theme, aes::Gadfly.Aesthetics,
    scales::Dict{Symbol, Gadfly.ScaleElement})

    Gadfly.assert_aesthetics_defined("Geom.segment", aes, :x, :y, :xend, :yend)

    function arrow{T<:Real}(x::T, y::T, xmax::T, ymax::T, xyrange::Vector{T})
        dx = xmax-x
        dy = ymax-y
        vl = 0.225*hypot(dy/xyrange[2], dx/xyrange[1])
        θ =  atan2(dy/xyrange[2], dx/xyrange[1])
        ϕ = pi/15
        xr = -vl*xyrange[1]*[cos(θ+ϕ), cos(θ-ϕ)]
        yr = -vl*xyrange[2]*[sin(θ+ϕ), sin(θ-ϕ)]
        arr = [(xmax+xr[1],ymax+yr[1]), (xmax,ymax), (xmax+xr[2],ymax+yr[2]) ]
        return arr
    end

    n = length(aes.x)
    color = ColorTypes.RGBA{Float32}(theme.default_color)
    default_aes = Gadfly.Aesthetics()  
    default_aes.color = DataArrays.DataArray(fill(color,n))

    aes = inherit(aes, default_aes) 

#    line_style = Gadfly.get_stroke_vector(theme.line_style)
    line_style = theme.line_style 
    if is(line_style, nothing)
        line_style = [] 
    end


# Geom.vector requires information about scales

if geom.arrow
    xscale = scales[:x]
    yscale = scales[:y]
    check = [xscale.minvalue, xscale.maxvalue, yscale.minvalue, yscale.maxvalue]
    if any( map(x -> is(x,nothing), check) )
        error("For Geom.vector, Scale minvalue and maxvalue must be manually provided for both axes")
    end
    fx = xscale.trans.f
    fy = yscale.trans.f
    xyrange = [fx(xscale.maxvalue)-fx(xscale.minvalue),
        fy(yscale.maxvalue)-fy(yscale.minvalue)]

     arrows = [ arrow(x, y, xend, yend, xyrange)
            for (x, y, xend, yend) in zip(aes.x, aes.y, aes.xend, aes.yend) ]

end

    
    segments = [ [(x,y), (xend,yend)]
        for (x, y, xend, yend) in zip(aes.x, aes.y, aes.xend, aes.yend) ]  
       
    classes = [string("geometry ", svg_color_class_from_label( aes.color_label([c])[1] ))
        for c in aes.color ]
    
    ctx = context()

    compose!( ctx, Compose.line(segments, geom.tag), stroke(aes.color), linewidth(theme.line_width), 
        strokedash(line_style), svgclass( classes )  )
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





