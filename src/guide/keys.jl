


##### NEW KEYS #####

struct ShapeKey <: Gadfly.GuideElement
    title::AbstractString
    labels::Vector{String}
    pos::Vector
end
ShapeKey(;title="Shape", labels=[""], pos=Float64[]) = ShapeKey(title, labels, pos)


"""
    Guide.shapekey[(; title="Shape", labels=[""], pos=Float64[])]
    Guide.shapekey(title, labels, pos)

Enable control of the auto-generated shapekey.  Set the key `title` and the item `labels`.
`pos` overrides [Theme(key_position=)](@ref Gadfly) and can be in either
relative (e.g. [0.7w, 0.2h] is the lower right quadrant), absolute (e.g. [0mm,
0mm]), or plot scale (e.g. [0,0]) coordinates.
"""
const shapekey = ShapeKey



function Guide.render(guide::Guide.ShapeKey, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)

    (theme.key_position == :none) && return Gadfly.Guide.PositionedGuide[]
    gpos = guide.pos
    (theme.key_position == :inside) && (gpos == Float64[]) &&  (gpos = [0.7w, 0.25h])

    # Aesthetics for keys: shape_key_title, shape_label (Function), shape_key_shapes (AbstractDict)    
    nshapes = length(unique(aes.shape))
    guide_title = (guide.title!="Shape" || aes.shape_key_title==nothing) ? guide.title : aes.shape_key_title
    shape_key_labels = !(guide.labels==[""]) ? guide.labels : aes.shape_label(1:nshapes)
    
    colors = [nothing]
    if (aes.shape_key_title !=nothing)  && (aes.color_key_title==aes.shape_key_title)
        colors = collect(keys(aes.color_key_colors))
    end
    
    title_context, title_width = Guide.render_key_title(guide_title, theme)
    ctxs = render_discrete_key(shape_key_labels, title_context, title_width, theme, shapes=1:nshapes, colors=colors)
    
    position = right_guide_position
    if gpos != Float64[]
        position = over_guide_position
        ctxs = [compose(context(), (context(gpos[1],gpos[2]), ctxs[1]))]
    elseif theme.key_position == :left
        position = left_guide_position
    elseif theme.key_position == :top
        position = top_guide_position
    elseif theme.key_position == :bottom
        position = bottom_guide_position
    end

    return [Guide.PositionedGuide(ctxs, 0, position)]
end








function render_discrete_key(labels::Vector{String}, title_ctx::Context, title_width::Measure, theme::Gadfly.Theme; 
    colors=[nothing], aes_color_label=nothing, shapes=[nothing])

    n = max(length(colors), length(shapes))
    shape1 = shapes[1]
    shapes = (shape1==nothing) ? fill(theme.key_swatch_shape, n) : theme.point_shapes[shapes]
    (colors[1]==nothing) && (colors = fill((theme.key_swatch_color==nothing) ? theme.default_color : theme.key_swatch_color, n))

    # only consider layouts with a reasonable number of columns
    maxcols = theme.key_max_columns < 1 ? 1 : theme.key_max_columns
    maxcols = min(n, maxcols)

    extents = text_extents(theme.key_label_font,
                        theme.key_label_font_size,
                        values(labels)...)

    ypad = 1.0mm
    title_height = title_ctx.box.a[2]
    entry_height = maximum([height for (width, height) in extents]) + ypad
    swatch_size = entry_height / 2

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
                colwidth = maximum([width for (width, height) in extents[m+1:m+nrows]])
                colwidth += swatch_size + 2xpad
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

            ctx = context(0, yoff + title_height,
                        ctxwidth, ctxheight - title_height,
                        units=UnitBox(0, 0, 1, colrows[1]))

            m = 0
            xpos = 0w
            for (i, nrows) in enumerate(colrows)
                colwidth = colwidths[i]
                
                x = [0.5cy]
                clrs = colors[m+1:m+nrows]
                shps = shapes[m+1:m+nrows]
                swatches_shapes = [f(x, [y].*cy, [swatch_size/1.5]) for (y,f) in enumerate(shps)]
                sw1 = [(context(), s, fill(c), fillopacity(theme.alphas[1]), stroke(theme.discrete_highlight_color(c)))
                     for (s,c) in zip(swatches_shapes, clrs)]
                swatches = compose!(context(), sw1...)

                swatch_labels = compose!(
                    context(),
                    text([2xpad + swatch_size], [y*cy for y in 1:nrows],
                        collect(values(labels))[m+1:m+nrows], [hleft], [vcenter]),
                    font(theme.key_label_font),
                    fontsize(theme.key_label_font_size),
                    fill(theme.key_label_color))

                col = compose!(context(xpos, yoff), swatches, swatch_labels)
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
                xpos += colwidths[i]
            end

            return compose!(outerctx, ctx,
                            # defeat webkit's asinine default drag behavior
                            jscall("drag(function() {}, function() {}, function() {})"),
                            svgclass("guide colorkey"))
        end

        return compose!(
            context(minwidth=max(title_width, ctxwidth),
                    minheight=ctxheight,
                    units=UnitBox()),
            ctxp)
    end

    return map(make_layout, 1:maxcols)
end




