


##### NEW KEYS #####

struct ShapeKey <: Gadfly.GuideElement
    title::AbstractString
    labels::Vector{<:AbstractString}
    pos::Vector
    visible::Bool
end
ShapeKey(;title="Shape", labels=AbstractString[], pos=[], visible=true) = ShapeKey(title, labels, pos, visible)
ShapeKey(v::Nothing) = ShapeKey(visible=false)
ShapeKey(title::AbstractString, labels::Vector{<:AbstractString}, pos::Vector) = ShapeKey(title, labels, pos, true)


"""
    Guide.shapekey[(; title="Shape", labels=String[], pos=Float64[])]
    Guide.shapekey(title, labels, pos)

Enable control of the auto-generated shapekey.  Set the key `title` and the item `labels`.
`pos` overrides [Theme(key_position=)](@ref Gadfly) and can be in either
relative (e.g. [0.7w, 0.2h] is the lower right quadrant), absolute (e.g. [0mm,
0mm]), or plot scale (e.g. [0,0]) coordinates. `Guide.shapekey(nothing)` will hide the key.
"""
const shapekey = ShapeKey



function render(guide::ShapeKey, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    (theme.key_position == :none || !guide.visible || isa(aes.shape[1], Function)) && return PositionedGuide[]
    gpos = guide.pos
    (theme.key_position == :inside) && isempty(gpos) &&  (gpos = [0.7w, 0.25h])

    # Aesthetics for keys: shape_key_title, shape_label (Function), shape_key_shapes (AbstractDict)
    nshapes = length(unique(aes.shape))
    guide_title = (guide.title≠"Shape" || aes.shape_key_title==nothing) ? guide.title : aes.shape_key_title
    shape_key_labels = isempty(guide.labels) ? aes.shape_label(1:nshapes) : guide.labels
    
    colors = Colorant[]
    if (aes.shape_key_title !=nothing)  && (aes.color_key_title==aes.shape_key_title)
        colors = collect(keys(aes.color_key_colors))
    end
    shapes = theme.point_shapes[1:nshapes]

    title_context, title_width = render_key_title2(guide_title, theme)
    ctxs = render_discrete_key(shape_key_labels, title_context, title_width, theme, shapes=shapes, colors=colors)
    
    position, stackable = right_guide_position, true
    if !isempty(gpos)
        position, stackable = over_guide_position, false
        ctxs = [compose(context(), (context(gpos[1],gpos[2]), ctxs[1]))]
    elseif theme.key_position == :left
        position = left_guide_position
    elseif theme.key_position == :top
        position = top_guide_position
    elseif theme.key_position == :bottom
        position = bottom_guide_position
    end

    return [PositionedGuide(ctxs, 0, position, stackable)]
end








function render_discrete_key(labels::Vector{<:AbstractString}, title_ctx::Context, title_width::Measure, theme::Gadfly.Theme;
    colors=Colorant[], aes_color_label=nothing, shapes=Function[], sizes=Measure[])

    labels = String.(labels)

    n = max(length(colors), length(shapes), length(sizes))
    n==0 && (n = length(labels))

    isempty(shapes) && (shapes = fill((theme.key_swatch_shape==nothing) ? theme.point_shapes[1] :  theme.key_swatch_shape, n))
    isempty(colors) && (colors = fill((theme.key_swatch_color==nothing) ? theme.default_color : theme.key_swatch_color, n))
    isempty(sizes) && (sizes = fill((theme.key_swatch_size==nothing) ? theme.point_size : theme.key_swatch_size, n))

    # only consider layouts with a reasonable number of columns
    maxcols = theme.key_max_columns < 1 ? 1 : theme.key_max_columns
    maxcols = min(n, maxcols)

    extents = text_extents(theme.key_label_font, theme.key_label_font_size, values(labels)...)
    text_widths, text_heights = first.(extents), last.(extents)

    ypad = 1.0mm
    title_height = title_ctx.box.a[2]
    swatch_size = 2*maximum(sizes)
    entry_height = max(swatch_size, maximum(text_heights)) + ypad

    # return a context with a lyout of numcols columns
    function make_layout(numcols)
        colrows = Array{Int}(undef, numcols)
        m = n
        for i in 1:numcols
            colrows[i] = ceil(Int, m/(1+numcols-i))
            m -= colrows[i]
        end
        
        xpad = 1mm
        colwidths = Array{Measure}(undef, numcols)
        m = 0
        for (i, nrows) in enumerate(colrows)
            if m == n
                colwidths[i] = 0mm
            else
                colwidth = maximum(text_widths[m+1:m+nrows])
                colwidth += entry_height + xpad
                colwidths[i] = colwidth
                m += nrows
            end
        end

        ctxwidth = sum(colwidths)
        ctxheight = entry_height * colrows[1] + title_height

        ctxp = ctxpromise() do draw_context
            yoff = 0.5h - ctxheight/2
            outerctx = context()

            compose!(outerctx, (context(xpad, yoff), title_ctx))

            ctx = context(0, yoff+title_height, ctxwidth, ctxheight-title_height, units=UnitBox(0, 0, 1, colrows[1]))

            m = 0
            xpos = 0w
            for (colwidth, nrows) in zip(colwidths, colrows)
            
                x = [0.5cy]
                clrs = colors[m+1:m+nrows]
                shps = shapes[m+1:m+nrows]
                szs = sizes[m+1:m+nrows]

                swatches_shapes = [f(x, [y-0.5].*cy, [s]) for (y,(f,s)) in enumerate(zip(shps, szs))]
                sw1 = [(context(), s, fill(c), fillopacity(theme.alphas[1]), stroke(theme.discrete_highlight_color(c)))
                     for (s,c) in zip(swatches_shapes, clrs)]
                swatches = compose!(context(), linewidth(theme.highlight_width), sw1...)

                swatch_labels = compose!(context(),
                text([entry_height+xpad], [0.5:nrows;]*cy, labels[m+1:m+nrows], [hleft], [vcenter]),
                    font(theme.key_label_font),
                    fontsize(theme.key_label_font_size),
                    fill(theme.key_label_color))

                col = compose!(context(xpos, 0, colwidth), swatches, swatch_labels)

                if aes_color_label != nothing
                    classes = [svg_color_class_from_label(aes_color_label([c])[1]) for c in clrs]
                    #class_jscalls = ["data(\"color_class\", \"$(c)\")" for c in classes]
                    compose!(col,
                        svgclass(classes),
                        jscall(["""
                            data(\"color_class\", \"$(c)\")
                            .click(Gadfly.colorkey_swatch_click)
                            """ for c in classes]))
                end
                compose!(ctx, col)

                m += nrows
                xpos += colwidth
            end

            return compose!(outerctx, ctx,
                            # defeat webkit's asinine default drag behavior
                            jscall("drag(function() {}, function() {}, function() {})"),
                            svgclass("guide colorkey"))
        end

        return compose!(context(minwidth=max(title_width, ctxwidth),
                    minheight=ctxheight, units=UnitBox()),
                    ctxp)
    end

    return map(make_layout, 1:maxcols)
end


function render_key_title2(title::AbstractString, theme::Gadfly.Theme)
    title_width, title_height = max_text_extents(theme.key_title_font, theme.key_title_font_size, title)

    if theme.guide_title_position == :left
        title_form = text(0.0w, title_height, title, hleft, vbottom)
    elseif theme.guide_title_position == :center
        title_form = text(0.5w, title_height, title, hcenter, vbottom)
    elseif theme.guide_title_position == :right
        title_form = text(1.0w, title_height, title, hright, vbottom)
    else
        error("$(theme.guide_title_position) is not a valid guide title position")
    end

    title_padding = 1.5mm
    title_context = compose!(
        context(0w, 0h, 1w, title_height + title_padding),
        title_form,
        stroke(nothing),
        font(theme.key_title_font),
        fontsize(theme.key_title_font_size),
        fill(theme.key_title_color))

    return title_context, title_width
end


struct SizeKey <: Gadfly.GuideElement
    title::AbstractString
    labels::Vector{<:AbstractString}
    pos::Vector{Compose.MeasureOrNumber}
    visible::Bool
end
SizeKey(;title="Size", labels=AbstractString[], pos=[], visible=true) = SizeKey(title, labels, pos, visible)
SizeKey(v::Nothing) = SizeKey(visible=false)
SizeKey(title::AbstractString, labels::Vector{<:AbstractString}, pos::Vector) = SizeKey(title, labels, pos, true)

"""
    Guide.sizekey[(; title="size", labels=String[], pos=[])]
    Guide.sizekey(title, labels, pos)

Enable control of the sizekey.  Set the key `title` and the item `labels`.
`pos` overrides [Theme(key_position=)](@ref Gadfly) and can be in either
relative (e.g. [0.7w, 0.2h] is the lower right quadrant), absolute (e.g. [0mm,
0mm]), or plot scale (e.g. [0,0]) coordinates. Currently `Guide.sizekey` will only work by adding
`Scale.size_discrete2` to the plot. `Guide.sizekey(nothing)` will hide the key.
"""
const sizekey = SizeKey

function render(guide::SizeKey, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    (theme.key_position==:none || !guide.visible || aes.size_key_vals===nothing) && return PositionedGuide[]
    gpos = guide.pos
    (theme.key_position==:inside) && isempty(gpos) &&  (gpos = [0.7w, 0.25h])

    # Aesthetics for keys: size_key_title, size_label (Function), size_key_vals (AbstractDict)    
    nsizes = length(unique(aes.size))
    guide_title = (guide.title≠"Size" || aes.size_key_title===nothing) ? guide.title : aes.size_key_title
    sizes = collect(keys(aes.size_key_vals))
    size_key_labels = isempty(guide.labels) ? aes.size_label(sizes) : guide.labels
    
    colors = Colorant[]
    if (aes.size_key_title≠nothing)  && (aes.color_key_title==aes.size_key_title)
        colors = collect(keys(aes.color_key_colors))
    end
    
    title_context, title_width = render_key_title2(guide_title, theme)
    ctxs = render_discrete_key(size_key_labels, title_context, title_width, theme, sizes=sizes, colors=colors)
    
    position, stackable = right_guide_position, true
    if !isempty(gpos)
        position, stackable = over_guide_position, false
        ctxs = [compose(context(), (context(gpos[1], gpos[2]), ctxs[1]))]
    elseif theme.key_position == :left
        position = left_guide_position
    elseif theme.key_position == :top
        position = top_guide_position
    elseif theme.key_position == :bottom
        position = bottom_guide_position
    end

    return [PositionedGuide(ctxs, 0, position, stackable)]
end



struct ManualDiscreteKey <: Gadfly.GuideElement
    title::AbstractString
    labels::Vector{<:AbstractString}
    pos::Vector
    colors::Vector{Colorant}
    shapes::Vector{Function}
    sizes::Vector{Measure}
    visible::Bool
end

function ManualDiscreteKey(;title="", labels=AbstractString[], pos=[], color=Colorant[], shape=Function[], size=Measure[])
    CT, ST, SZT = eltype(color), eltype(shape), eltype(size)
    ncolors, nshapes, nsizes =  length(color), length(shape), length(size)
    n = max(ncolors, nshapes, nsizes)
    ncolors==1 && (color = repeat(color, n))
    nshapes==1 && (shape = repeat(shape, n))
    nsizes==1 && (size = repeat(size, n))

    theme = Gadfly.current_theme()
    clrs = CT<:Int ? theme.discrete_colormap(maximum(color))[color] : Gadfly.parse_colorant(color)
    shps = ST<:Int ? theme.point_shapes[shape] : shape
    szs = SZT<:Int ? theme.discrete_sizemap(maximum(size))[size] : size

    cataes = [clrs, shps, szs]
    notempty = .!isempty.(cataes)
    if any(notempty)
        swatches = collect(Tuple, zip(cataes[notempty]...))
        !allunique(swatches) && error("Swatches should not be repeated in a manual key")
    end
    return ManualDiscreteKey(title, labels, pos, clrs, shps, szs,  true)
end


"""
    Guide.manual_discrete_key(title::String, labels::Vector{String};
        pos=[], color=Colorant[], shape=Function[], size=Measure[])

Manually define a discrete key with the legend `title` and `labels`, and swatch `color`, `shape` and `size`.
The swatch aesthetics can be Vectors of specific types (as above), or integer ranges.
Integer ranges refer to the order of items in the discrete Theme palettes [Discrete Scales](@ref).
Set the key position inside using `pos` (see [`Guide.sizekey`](@ref), [`Guide.shapekey`](@ref)).
"""
manual_discrete_key(title::AbstractString, labels::Vector{<:AbstractString}; kwargs...) =
    ManualDiscreteKey(title=title, labels=labels; kwargs...)


"""
    Guide.manual_color_key(title::String, labels::Vector{String}, color::AbstractVector=
        1:length(labels); pos=[], shape=Function[], size=Measure[])

Similar to [`Guide.manual_discrete_key`](@ref). `color` can be Ints, or Colors and/or Strings
(default is Ints).
"""
function manual_color_key(title::AbstractString, labels::Vector{<:AbstractString}, 
        color::AbstractVector=1:length(labels); kwargs...)
    ManualDiscreteKey(title=title, labels=labels, color=color; kwargs...)
end


function render(guide::ManualDiscreteKey, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    gpos = guide.pos
    (theme.key_position == :inside) && isempty(gpos) &&  (gpos = [0.7w, 0.25h])

    title_context, title_width = render_key_title2(guide.title, theme)
    ctxs = render_discrete_key(guide.labels, title_context, title_width, theme, 
        shapes=guide.shapes, colors=guide.colors, sizes=guide.sizes)
    
    position, stackable = right_guide_position, true
    if !isempty(gpos)
        position, stackable = over_guide_position, false
        ctxs = [compose(context(), (context(gpos[1],gpos[2]), ctxs[1]))]
    elseif theme.key_position == :left
        position = left_guide_position
    elseif theme.key_position == :top
        position = top_guide_position
    elseif theme.key_position == :bottom
        position = bottom_guide_position
    end

    return [PositionedGuide(ctxs, 0, position, stackable)]
end


