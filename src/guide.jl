module Guide

using Colors
using Compose
using DataStructures
using Gadfly
using IterTools
using JSON

import Gadfly: render, escape_id, default_statistic, jsdata, jsplotdata,
               svg_color_class_from_label


# Where the guide should be placed in relation to the plot.
abstract type GuidePosition end
struct TopGuidePosition    <: GuidePosition end
struct RightGuidePosition  <: GuidePosition end
struct BottomGuidePosition <: GuidePosition end
struct LeftGuidePosition   <: GuidePosition end
struct UnderGuidePosition  <: GuidePosition end
struct OverGuidePosition   <: GuidePosition end

const top_guide_position    = TopGuidePosition()
const right_guide_position  = RightGuidePosition()
const bottom_guide_position = BottomGuidePosition()
const left_guide_position   = LeftGuidePosition()
const under_guide_position  = UnderGuidePosition()
const over_guide_position   = OverGuidePosition()

struct QuestionMark <: Gadfly.GuideElement
end

const questionmark = QuestionMark

function render(guide::QuestionMark, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    text_color = theme.background_color == nothing ?
            colorant"black" : distinguishable_colors(2,theme.background_color)[2]
    text_box = compose!( context(),
        text(1w,0h+2px,"?",hright,vtop),
        fill(text_color),
        svgclass("text_box"),
        jscall(
            """
            mouseenter(Gadfly.helpscreen_visible)
            .mouseleave(Gadfly.helpscreen_hidden)
            """))

    root = compose!(
        context(withjs=true, units=UnitBox()),
        text_box,
        svgclass("guide questionmark"),
        fillopacity(0.0))

    return [PositionedGuide([root], 0, over_guide_position)]
end


struct HelpScreen <: Gadfly.GuideElement
end

const helpscreen = HelpScreen

function render(guide::HelpScreen, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    box_color = theme.background_color == nothing ?
            colorant"black" : distinguishable_colors(2,theme.background_color)[2]
    text_color = distinguishable_colors(2,box_color)[2]
    text_strings = ["h,j,k,l,arrows,drag to pan",
                    "i,o,+,-,scroll,shift-drag to zoom",
                    "r,dbl-click to reset",
                    "c for coordinates",
                    "? for help"]
    nlines = length(text_strings)
    max_text_width, max_text_height = max_text_extents(
          theme.major_label_font, theme.major_label_font_size, text_strings...)
    text_box = compose!(context(),
        (context(),
          text([0.5w], [0.5h+i*max_text_height for i=-(nlines-1)/2:(nlines-1)/2],
               text_strings, [hcenter], [vcenter]),
          font(theme.major_label_font),
          fontsize(theme.major_label_font_size),
          fill(text_color)),
        (context(),
          rectangle(0.5w-max_text_width/2*1.1, 0.5h-max_text_height*nlines/2*1.1,
                    max_text_width*1.1, max_text_height*nlines*1.1),
          fill(box_color)),
        svgclass("text_box"))

    root = compose!(
        context(withjs=true, units=UnitBox()),
        text_box,
        svgclass("guide helpscreen"),
        fillopacity(0.0))

    return [PositionedGuide([root], 0, over_guide_position)]
end

struct CrossHair <: Gadfly.GuideElement
end

const crosshair = CrossHair

function render(guide::CrossHair, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    text_color = theme.background_color == nothing ?
            colorant"black" : distinguishable_colors(2,theme.background_color)[2]
    text_box = compose!(
        context(),
        text(1w-20pt,0h+2px,"",hright,vtop),
        fill(text_color),
        svgclass("text_box"))

    root = compose!(
        context(withjs=true, units=UnitBox()),
        text_box,
        svgclass("guide crosshair"),
        fillopacity(0.0))

    return [PositionedGuide([root], 0, over_guide_position)]
end


# A guide graphic is a position associated with one or more contexts.
# Multiple contexts represent multiple layout possibilites that will be
# optimized over.
struct PositionedGuide
    ctxs::Vector{Context}
    order::Int
    position::GuidePosition
end


struct PanelBackground <: Gadfly.GuideElement
end

const background = PanelBackground

render(guide::Gadfly.GuideElement, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, dynamic::Bool=true) =
        render(guide, theme, aes)

function render(guide::PanelBackground, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    back = compose!(context(order=-1),
                    rectangle(),
                    svgclass("guide background"),
                    stroke(theme.panel_stroke),
                    fill(theme.panel_fill),
                    svgattribute("pointer-events", "visible"))

    return [PositionedGuide([back], 0, under_guide_position)]
end


struct ColorKey <: Gadfly.GuideElement
    title::Union{AbstractString, (Nothing)}
    labels::Union{Vector{String}, (Nothing)}
    pos::Union{Vector, (Nothing)}
end
ColorKey(;title=nothing, labels=nothing, pos=nothing) = ColorKey(title, labels, pos)

@deprecate ColorKey(title) ColorKey(title=title)

# ColorKey() = ColorKey(nothing)

"""
    Guide.colorkey[(; title=nothing, labels=nothing, pos=nothing)]
    Guide.colorkey(title, labels, pos)

Enable control of the auto-generated colorkey.  Set the colorkey `title` for
any plot, and the item `labels` for plots with a discrete color scale.  `pos`
overrides [Theme(key_position=)](@ref Gadfly) and can be in either
relative (e.g. [0.7w, 0.2h] is the lower right quadrant), absolute (e.g. [0mm,
0mm]), or plot scale (e.g. [0,0]) coordinates.
"""
const colorkey = ColorKey

# A helper for render(::ColorKey) for rendering guides for discrete color
# scales.
function render_discrete_color_key(colors::Vector{C},
                         labels::OrderedDict{C, AbstractString},
                         aes_color_label,
                         title_ctx::Context,
                         title_width::Measure,
                         theme::Gadfly.Theme) where C<:Color

    n = length(colors)

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

                if theme.colorkey_swatch_shape == :square
                    swatches_shapes = rectangle(
                        [xpad], [y*cy - swatch_size/2 for y in 1:nrows],
                        [swatch_size], [swatch_size])
                elseif theme.colorkey_swatch_shape == :circle
                    swatches_shapes = Shape.circle([0.5cy], 1:nrows, [swatch_size/2])
                end
                cs = colors[m+1:m+nrows]
                swatches = compose!(context(), swatches_shapes, stroke(theme.discrete_highlight_color.(cs)),
                    fill(cs), fillopacity(theme.alphas[1]))

                swatch_labels = compose!(
                    context(),
                    text([2xpad + swatch_size], [y*cy for y in 1:nrows],
                         collect(values(labels))[m+1:m+nrows], [hleft], [vcenter]),
                    font(theme.key_label_font),
                    fontsize(theme.key_label_font_size),
                    fill(theme.key_label_color))

                col = compose!(context(xpos, yoff), swatches, swatch_labels)
                if aes_color_label != nothing
                    classes = [svg_color_class_from_label(aes_color_label([c])[1]) for c in cs]
                    #class_jscalls = ["data(\"color_class\", \"$(c)\")"
                                     #for c in classes]
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


# A helper for render(::ColorKey) for rendering guides for continuous color
# scales.
function render_continuous_color_key(colors::Dict,
                                     labels::OrderedDict{Color, AbstractString},
                                     color_function::Function,
                                     title_context::Context,
                                     title_width::Measure,
                                     theme::Gadfly.Theme)

    entry_width, entry_height = max_text_extents(theme.key_label_font,
                                                 theme.key_label_font_size,
                                                 values(labels)...)

    numlabels = length(labels)
    title_height = title_context.box.a[2]
    total_height = 1.5 * numlabels * entry_height + title_height
    swatch_width = entry_height / 2
    xoff = 2mm
    padding = 1mm
    entry_width += 2padding + swatch_width + xoff

    ctx = context(minwidth=max(title_width, entry_width),
                  minheight=total_height, units=UnitBox())

    yoff = 0.5h - total_height/2

    compose!(ctx, (context(xoff, yoff), title_context))

    # color bar
    compose!(ctx,
        (context(xoff, yoff + title_height,
                 1w, total_height, units=UnitBox()),
         rectangle(
             [0],
             [1*cy - i*total_height / theme.key_color_gradations
              for i in 1:theme.key_color_gradations],
             [swatch_width],
             [total_height / theme.key_color_gradations]),

         #grid lines
         (context(),
          line([[(0, 1 - y), (swatch_width, 1 - y)] for y in values(colors)]),
          linewidth(theme.grid_line_width),
          stroke(colorant"white")),

         fill([color_function((i-1) / (theme.key_color_gradations - 1))
               for i in 1:theme.key_color_gradations]),
         stroke(nothing), fillopacity(theme.alphas[1]),
         svgattribute("shape-rendering", "crispEdges")))

    compose!(ctx,
        (context(xoff + swatch_width + padding, yoff + title_height,
                 1w, total_height, units=UnitBox()),
         text([0],
              [1 - y for y in values(colors)],
              [labels[c] for c in keys(colors)],
              [hleft], [vcenter]),
         fill(theme.key_label_color),
         font(theme.key_label_font),
         fontsize(theme.key_label_font_size)),
         svgclass("guide colorkey"))

    return [ctx]
end


function render_key_title(title::AbstractString, theme::Gadfly.Theme)
    title_width, title_height = max_text_extents(theme.key_title_font,
                                                 theme.key_title_font_size,
                                                 title)

    if theme.guide_title_position == :left
        title_form = text(0.0w, title_height, title, hleft, vbottom)
    elseif theme.guide_title_position == :center
        title_form = text(0.5w, title_height, title, hcenter, vbottom)
    elseif theme.guide_title_position == :right
        title_form = text(1.0w, title_height, title, hright, vbottom)
    else
        error("$(theme.guide_title_position) is not a valid guide title position")
    end

    title_padding = 4mm
    title_context = compose!(
        context(0w, 0h, 1w, title_height + title_padding),
        title_form,
        stroke(nothing),
        font(theme.key_title_font),
        fontsize(theme.key_title_font_size),
        fill(theme.key_title_color))

    return title_context, title_width
end


function render(guide::ColorKey, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)

    (theme.key_position == :none || isempty(aes.color_key_colors)) && return PositionedGuide[]
    gpos = guide.pos
    (theme.key_position == :inside && gpos === nothing) &&  (gpos = [0.7w, 0.25h])

    used_colors = Set{Color}()
    colors = Array{Color}(undef, 0) # to preserve ordering
    labels = OrderedDict{Color, Set{AbstractString}}()

    continuous_guide = false
    guide_title = guide.title

    if guide_title === nothing && aes.color_key_title !== nothing
        guide_title = aes.color_key_title
    end

    if aes.color_key_colors != nothing &&
       aes.color_key_continuous != nothing &&
       aes.color_key_continuous
        continuous_guide = true
    end

    color_key_labels = aes.color_label(keys(aes.color_key_colors))
    if !continuous_guide && (guide.labels != nothing)
        color_key_labels = guide.labels
    end

    for (color, label) in zip(keys(aes.color_key_colors), color_key_labels)
        if !in(color, used_colors)
            push!(used_colors, color)
            push!(colors, color)
            labels[color] = Set{AbstractString}()
            push!(labels[color], label)
        else
            push!(labels[color], label)
        end
    end

    if guide_title === nothing
        guide_title = "Color"
    end

    pretty_labels = OrderedDict{Color, AbstractString}()
    for (color, label) in labels
        pretty_labels[color] = join(labels[color], ", ")
    end

    title_context, title_width = render_key_title(guide_title, theme)

    theme.colorkey_swatch_shape != :circle && theme.colorkey_swatch_shape != :square &&
            error("$(theme.colorkey_swatch_shape) is not a valid color key swatch shape")

    if continuous_guide
        ctxs = render_continuous_color_key(aes.color_key_colors,
                                           pretty_labels,
                                           aes.color_function,
                                           title_context,
                                           title_width, theme)
    else
        ctxs = render_discrete_color_key(colors, pretty_labels,
                                         aes.color_label,
                                         title_context,
                                         title_width, theme)
    end

    if aes.shape != nothing
        # TODO: Draw key for shapes. We need to think about how to make this
        # work. Do we need to optimize number of columns for shape and size
        # keys? I'm guessing it's not worth it.
        #
        # In that case I think we'll have different paths depending on whether
        # there is a color key or not. If there is, we need to position shape
        # and size keys in the deferred contexts. If there isn't we lay them out
        # statically with hstack.
    end

    position = right_guide_position
    if gpos != nothing
        position = over_guide_position
        ctxs = [compose(context(), (context(gpos[1],gpos[2]), ctxs[1]))]
    elseif theme.key_position == :left
        position = left_guide_position
    elseif theme.key_position == :right
        position = right_guide_position
    elseif theme.key_position == :top
        position = top_guide_position
    elseif theme.key_position == :bottom
        position = bottom_guide_position
    end

    return [PositionedGuide(ctxs, 0, position)]
end


struct ManualColorKey{C<:Color} <: Gadfly.GuideElement
    title::Union{AbstractString, (Nothing)}
    labels::OrderedDict{C, AbstractString}
end
function ManualColorKey(title, labels, colors::Vector{C}) where {C<:Color}
    labeldict = OrderedDict{C, AbstractString}()
    # ensure uniqueness of colors, fixes #1170
    for (c, l) in zip(colors, labels)
        haskey(labeldict, c) && error("Colors should not appear more than once")
        labeldict[c] = l
    end
    ManualColorKey(title, labeldict)
end
ManualColorKey(title, labels, colors) =
        ManualColorKey(title, labels, Gadfly.parse_colorant(colors))

"""
    Guide.manual_color_key(title, labels, colors)

Manually define a color key with the legend `title` and item `labels` and `colors`.
"""
const manual_color_key = ManualColorKey

function render(guide::ManualColorKey, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    if theme.key_position == :none
        return PositionedGuide[]
    end

    guide_title = guide.title

    if guide_title === nothing && aes.color_key_title !== nothing
        guide_title = aes.color_key_title
    end

    if guide_title === nothing
        guide_title = "Color"
    end

    title_context, title_width = render_key_title(guide_title, theme)

    ctxs = render_discrete_color_key(collect(keys(guide.labels)), guide.labels, nothing, title_context, title_width, theme)

    position = right_guide_position
    if theme.key_position == :left
        position = left_guide_position
    elseif theme.key_position == :right
        position = right_guide_position
    elseif theme.key_position == :top
        position = top_guide_position
    elseif theme.key_position == :bottom
        position = bottom_guide_position
    end

    return [PositionedGuide(ctxs, 0, position)]
end


struct XTicks <: Gadfly.GuideElement
    label::Bool
    ticks::Union{(Nothing), Symbol, AbstractArray}
    orientation::Symbol

    function XTicks(label, ticks, orientation)
        isa(ticks, Symbol) && ticks != :auto &&
                error("$(ticks) is not a valid value for the `ticks` parameter")
        new(label, ticks, orientation)
    end
end

XTicks(; label=true, ticks=:auto, orientation=:auto) = XTicks(label, ticks, orientation)

"""
    Guide.xticks[(; label=true, ticks=:auto, orientation=:auto)]
    Guide.xticks(label, ticks, orientation)

Formats the tick marks and labels for the x-axis.  `label` toggles the label
visibility.  `ticks` can also be an array of locations, or `nothing`.
`orientation` can also be `:horizontal` or `:vertical`.
"""
const xticks = XTicks

default_statistic(guide::XTicks) =
    guide.ticks == nothing ? Stat.identity() : Stat.xticks(ticks=guide.ticks)

function render(guide::XTicks, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, dynamic::Bool=true)
    guide.ticks == nothing && return PositionedGuide[]

    if Gadfly.issomething(aes.xtick)
        ticks = aes.xtick
        tickvisibility = aes.xtickvisible
        scale = aes.xtickscale

        T = eltype(aes.xtick)
        labels = AbstractString[]
        for scale_ticks in groupby(x -> x[1], zip(scale, ticks))
            append!(labels, aes.xtick_label(T[t for (s, t) in scale_ticks]))
        end
    else
        labels = AbstractString[]
        ticks = Any[]
        tickvisibility = Bool[]
        scale = Any[]
    end

    if Gadfly.issomething(aes.xgrid)
        grids = aes.xgrid
        gridvisibility = length(grids) < length(ticks) ?  tickvisibility[2:end] : tickvisibility
    else
        grids = Any[]
        gridvisibility = Bool[]
    end

    sum(gridvisibility) == 0 && sum(tickvisibility) == 0 && return PositionedGuide[]

    # grid lines
    grid_line_style = Gadfly.get_stroke_vector(theme.grid_line_style)
    static_grid_lines = compose!(
        context(withoutjs=true),
        line([[(t, 0h), (t, 1h)] for t in grids[gridvisibility]]),
        stroke(theme.grid_color),
        linewidth(theme.grid_line_width),
        strokedash(grid_line_style),
        svgclass("guide xgridlines yfixed"))

    if dynamic
        dynamic_grid_lines = compose!(
            context(withjs=true),
            line([[(t, 0h), (t, 1h)] for t in grids]),
            visible(gridvisibility),
            stroke(theme.grid_color),
            linewidth(theme.grid_line_width),
            strokedash(grid_line_style),
            svgclass("guide xgridlines yfixed"),
            svgattribute("gadfly:scale", scale),
            jsplotdata("focused_xgrid_color",
                       "\"#$(hex(theme.grid_color_focused))\""),
            jsplotdata("unfocused_xgrid_color",
                       "\"#$(hex(theme.grid_color))\""))
        grid_lines = compose!(context(), static_grid_lines, dynamic_grid_lines)
    else
        grid_lines = compose!(context(), static_grid_lines)
    end

    guide.label || return [PositionedGuide([grid_lines], 0, under_guide_position)]

    label_sizes = text_extents(theme.minor_label_font,
                               theme.minor_label_font_size,
                               labels...)
    label_widths = [width for (width, height) in label_sizes]
    label_heights = [height for (width, height) in label_sizes]

    padding = 1mm

    hlayout = ctxpromise() do draw_context
        static_labels = compose!(
            context(withoutjs=true),
            text(ticks[tickvisibility], [0h + padding], labels[tickvisibility],
                 [hcenter], [vtop]),
            fill(theme.minor_label_color),
            font(theme.minor_label_font),
            fontsize(theme.minor_label_font_size),
            svgclass("guide xlabels"))

        dynamic_labels = compose!(
            context(withjs=true),
            text(ticks, [1h - padding], labels, [hcenter], [vbottom]),
            visible(tickvisibility),
            fill(theme.minor_label_color),
            font(theme.minor_label_font),
            fontsize(theme.minor_label_font_size),
            svgattribute("gadfly:scale", scale),
            svgclass("guide xlabels"))

        return compose!(context(), static_labels, dynamic_labels)
    end
    hlayout_context = compose!(context(minwidth=sum(label_widths[tickvisibility]),
                                       minheight=2*padding + maximum(label_heights[tickvisibility])),
                               hlayout)

    vlayout = ctxpromise() do draw_context
        static_labels = compose!(
            context(withoutjs=true),
            text(ticks[tickvisibility],
                 [padding],
                 labels[tickvisibility],
                 [hright], [vcenter],
                 [Rotation(-0.5pi, tick, padding) for tick in ticks[tickvisibility]]),
            fill(theme.minor_label_color),
            font(theme.minor_label_font),
            fontsize(theme.minor_label_font_size),
            svgclass("guide xlabels"))

        dynamic_labels = compose!(
            context(withjs=true),
            text(ticks, [padding], labels, [hright], [vbottom],
                 [Rotation(-0.5pi, tick, padding) for tick in ticks]),
            visible(tickvisibility),
            fill(theme.minor_label_color),
            font(theme.minor_label_font),
            fontsize(theme.minor_label_font_size),
            svgattribute("gadfly:scale", scale),
            svgclass("guide xlabels"))

        return compose!(context(), static_labels, dynamic_labels)

    end
    vpenalty = 3
    vlayout_context = compose!(context(minwidth=sum(label_heights[tickvisibility]),
                                       minheight=2padding + maximum(label_widths[tickvisibility]),
                                       penalty=vpenalty), vlayout)

    if guide.orientation == :horizontal
        contexts = [hlayout_context]
    elseif guide.orientation == :vertical
        contexts = [vlayout_context]
    elseif guide.orientation == :auto
        contexts = [hlayout_context, vlayout_context]
    else
        error("$(guide.layout) is not a valid orientation for Guide.yticks")
    end

    return [PositionedGuide(contexts, 10,
                            bottom_guide_position),
            PositionedGuide([grid_lines], 0, under_guide_position)]
end


struct YTicks <: Gadfly.GuideElement
    label::Bool
    ticks::Union{(Nothing), Symbol, AbstractArray}
    orientation::Symbol

    function YTicks(label, ticks, orientation)
        isa(ticks, Symbol) && ticks != :auto &&
                error("$(ticks) is not a valid value for the `ticks` parameter")
        new(label, ticks, orientation)
    end
end

YTicks(; label=true, ticks=:auto, orientation=:horizontal) = YTicks(label, ticks, orientation)

"""
    Guide.yticks[(; label=true, ticks=:auto, orientation=:horizontal)]
    Guide.yticks(ticks, label, orientation)

Formats the tick marks and labels for the y-axis.  `label` toggles the label
visibility.  `ticks` can also be an array of locations, or `nothing`.
`orientation` can also be `:auto` or `:vertical`.
"""
const yticks = YTicks

function default_statistic(guide::YTicks)
    if guide.ticks == nothing
        return Stat.identity()
    else
        return Stat.yticks(ticks=guide.ticks)
    end
end

function render(guide::YTicks, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics, dynamic::Bool=true)
    if guide.ticks == nothing
        return PositionedGuide[]
    end

    if Gadfly.issomething(aes.ytick)
        ticks = aes.ytick
        tickvisibility = aes.ytickvisible
        scale = aes.ytickscale
        T = eltype(aes.ytick)
        labels = AbstractString[]
        for scale_ticks in groupby(x -> x[1], zip(scale, ticks))
            append!(labels, aes.ytick_label(T[t for (s, t) in scale_ticks]))
        end
    else
        labels = AbstractString[]
        ticks = Any[]
        tickvisibility = Bool[]
        scale = Any[]
    end

    if Gadfly.issomething(aes.ygrid)
        grids = aes.ygrid
        if length(grids) < length(ticks)
            gridvisibility = tickvisibility[2:end]
        else
            gridvisibility = tickvisibility
        end
    else
        grids = Any[]
        gridvisibility = Bool[]
    end

    if sum(gridvisibility) == 0 && sum(tickvisibility) == 0
        return PositionedGuide[]
    end

    # grid lines
    grid_line_style = Gadfly.get_stroke_vector(theme.grid_line_style)
    static_grid_lines = compose!(
        context(withoutjs=true),
        line([[(0w, t), (1w, t)] for t in grids[gridvisibility]]),
        stroke(theme.grid_color),
        linewidth(theme.grid_line_width),
        strokedash(grid_line_style),
        svgclass("guide ygridlines xfixed"))

    if dynamic
        dynamic_grid_lines = compose!(
            context(withjs=true),
            line([[(0w, t), (1w, t)] for t in grids]),
            visible(gridvisibility),
            stroke(theme.grid_color),
            linewidth(theme.grid_line_width),
            strokedash(grid_line_style),
            svgclass("guide ygridlines xfixed"),
            svgattribute("gadfly:scale", scale),
            jsplotdata("focused_ygrid_color",
                   "\"#$(    hex(theme.grid_color_focused))\""),
            jsplotdata("unfocused_ygrid_color",
                   "\"#$(hex(theme.grid_color))\""))
        grid_lines = compose!(context(), static_grid_lines, dynamic_grid_lines)
    else
        grid_lines = compose!(context(), static_grid_lines)
    end

    if !guide.label
        return [PositionedGuide([grid_lines], 0, under_guide_position)]
    end

    label_sizes = text_extents(theme.minor_label_font,
                               theme.minor_label_font_size,
                               labels...)
    label_widths = [width for (width, height) in label_sizes]
    label_heights = [height for (width, height) in label_sizes]
    padding = 1mm

    hlayout = ctxpromise() do draw_context
        static_labels = compose!(
            context(withoutjs=true),
            text([1.0w - padding], ticks[tickvisibility], labels[tickvisibility],
                 [hright], [vcenter]),
            fill(theme.minor_label_color),
            font(theme.minor_label_font),
            fontsize(theme.minor_label_font_size),
            svgclass("guide ylabels"))

        dynamic_labels = compose!(
            context(withjs=true),
            text([1.0w - padding], ticks, labels,
                 [hright], [vcenter]),
            visible(tickvisibility),
            fill(theme.minor_label_color),
            font(theme.minor_label_font),
            fontsize(theme.minor_label_font_size),
            svgattribute("gadfly:scale", scale),
            svgclass("guide ylabels"))

        return compose!(context(), static_labels, dynamic_labels)
    end
    hpenalty = 3
    hlayout_context =
        compose!(context(minwidth=maximum(label_widths[tickvisibility]) + 2padding,
                         minheight=sum(label_heights[tickvisibility]),
                         penalty=hpenalty), hlayout)

    vlayout = ctxpromise() do draw_context
        static_grid_lines = compose!(
            context(),
            text([1.0w - padding], ticks[tickvisibility], labels[tickvisibility],
                 [hcenter], [vbottom],
                 [Rotation(-0.5pi, (1.0w - padding, tick))
                  for tick in ticks[tickvisibility]]),
            fill(theme.minor_label_color),
            font(theme.minor_label_font),
            fontsize(theme.minor_label_font_size),
            svgclass("guide ylabels"))

        dynamic_grid_lines = compose!(
            context(),
            text([1.0w - padding], ticks, labels,
                 [hcenter], [vbottom],
                 [Rotation(-0.5pi, (1.0w - padding, tick))
                  for tick in ticks[tickvisibility]]),
            visible(tickvisibility),
            fill(theme.minor_label_color),
            font(theme.minor_label_font),
            fontsize(theme.minor_label_font_size),
            svgattribute("gadfly:scale", scale),
            svgclass("guide ylabels"))

        return compose!(context(), static_grid_lines, dynamic_grid_lines)
    end
    vlayout_context =
        compose!(context(minwidth=maximum(label_heights[tickvisibility]),
                         minheight=sum(label_widths[tickvisibility])),
                 vlayout)

    if guide.orientation == :horizontal
        contexts = [hlayout_context]
    elseif guide.orientation == :vertical
        contexts = [vlayout_context]
    elseif guide.orientation == :auto
        contexts = [hlayout_context, vlayout_context]
    else
        error("$(guide.layout) is not a valid orientation for Guide.yticks")
    end

    return [PositionedGuide(contexts, 10,
                            left_guide_position),
            PositionedGuide([grid_lines], 0, under_guide_position)]
end


# X-axis label Guide
struct XLabel <: Gadfly.GuideElement
    label::Union{(Nothing), AbstractString}
    orientation::Symbol
end
XLabel(label; orientation=:auto) = XLabel(label, orientation)

"""
    Guide.xlabel(label, orientation=:auto)

Sets the x-axis label for the plot.  `label` is either a `String` or `nothing`.
`orientation` can also be `:horizontal` or `:vertical`.
"""
const xlabel = XLabel

function render(guide::XLabel, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    if guide.label === nothing || isempty(guide.label)
        return nothing
    end

    text_width, text_height = max_text_extents(theme.major_label_font,
                                               theme.major_label_font_size,
                                               guide.label)

    padding = 3mm
    hlayout = ctxpromise() do draw_context
        return compose!(context(),
                        text(0.5w, 0h + padding, guide.label, hcenter, vtop),
                        stroke(nothing),
                        fill(theme.major_label_color),
                        font(theme.major_label_font),
                        fontsize(theme.major_label_font_size))
    end
    hlayout_context = compose!(context(minwidth=text_width + 2padding,
                                       minheight=text_height + 2padding),
                               hlayout)

    vlayout = ctxpromise() do draw_context
        return compose!(context(),
                        text(0.5w, padding, guide.label, hright, vcenter,
                             Rotation(-0.5pi, 0.5w, padding)),
                        stroke(nothing),
                        fill(theme.major_label_color),
                        font(theme.major_label_font),
                        fontsize(theme.major_label_font_size))
    end
    vpenalty = 3
    vlayout_context = compose!(context(minwidth=text_height + 2padding,
                                       minheight=text_width + 2padding,
                                       penalty=3),
                               vlayout)

    if guide.orientation == :horizontal
        contexts = [hlayout_context]
    elseif guide.orientation == :vertical
        contexts = [vlayout_context]
    elseif guide.orientation == :auto
        contexts = [hlayout_context, vlayout_context]
    else
        error("$(guide.layout) is not a valid orientation for Guide.xlabel")
    end

    return [PositionedGuide(contexts, 0, bottom_guide_position)]
end


# Y-axis label Guide
struct YLabel <: Gadfly.GuideElement
    label::Union{(Nothing), AbstractString}
    orientation::Symbol
end
YLabel(label; orientation=:auto) = YLabel(label, orientation)

"""
    Guide.ylabel(label, orientation=:auto)

Sets the y-axis label for the plot.  `label` is either a `String` or `nothing`.
`orientation` can also be `:horizontal` or `:vertical`.
"""
const ylabel = YLabel


function render(guide::YLabel, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    if guide.label === nothing || isempty(guide.label)
        return nothing
    end

    text_width, text_height = max_text_extents(theme.major_label_font,
                                               theme.major_label_font_size,
                                               guide.label)

    padding = 2mm
    hlayout = ctxpromise() do draw_context
        return compose!(context(),
                        text(1.0w - padding, 0.5h, guide.label, hright, vcenter),
                        stroke(nothing),
                        fill(theme.major_label_color),
                        font(theme.major_label_font),
                        fontsize(theme.major_label_font_size))
    end
    hlayout_context = compose!(context(minwidth=text_width + 2padding,
                                       minheight=text_height + 2padding), hlayout)

    vlayout = ctxpromise() do draw_context
        return compose!(context(),
                        text(0.5w, 0.5h - padding, guide.label, hcenter, vcenter, Rotation(-0.5pi)),
                        stroke(nothing),
                        fill(theme.major_label_color),
                        font(theme.major_label_font),
                        fontsize(theme.major_label_font_size))
    end
    vlayout_context = compose!(context(minwidth=text_height + 2padding,
                                       minheight=text_width + 2padding), vlayout)

    if guide.orientation == :horizontal
        contexts = [hlayout_context]
    elseif guide.orientation == :vertical
        contexts = [vlayout_context]
    elseif guide.orientation == :auto
        contexts = [hlayout_context, vlayout_context]
    else
        error("$(guide.layout) is not a valid orientation for Guide.ylabel")
    end

    return [PositionedGuide(contexts, 0, left_guide_position)]
end

# Title Guide
struct Title <: Gadfly.GuideElement
    label::Union{(Nothing), AbstractString}
end

"""
    Geom.title(title)

Set the plot title.
"""
const title = Title

function render(guide::Title, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    if guide.label === nothing || isempty(guide.label)
        return nothing
    end

    (text_width, text_height) = max_text_extents(theme.major_label_font,
                                                 theme.major_label_font_size,
                                                 guide.label)

    padding = 2mm
    ctx = compose!(
        context(minwidth=text_width, minheight=text_height + padding),
        text(0.5w, 1h - text_height - padding, guide.label, hcenter, vtop),
        stroke(nothing),
        fill(theme.major_label_color),
        font(theme.major_label_font),
        fontsize(theme.major_label_font_size))

    return [PositionedGuide([ctx], 0, top_guide_position)]
end


struct XRug <: Gadfly.GuideElement
end

"""
    Guide.xrug

Draw a short vertical lines along the x-axis of a plot at the positions in the `x` aesthetic.
"""
const xrug = XRug

function render(guide::XRug, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Guide.xrug", aes, :x)
    padding = 0.4mm

    ctx = compose!(context(minheight=theme.rug_size),
        (context(clip=true),
         line([[(x, 0h + padding), (x, 1h - padding)] for x in aes.x]),
         stroke(theme.default_color),
         linewidth(theme.line_width),
         svgclass("guide yfixed")))

    return [PositionedGuide([ctx], 20, bottom_guide_position)]
end


struct YRug <: Gadfly.GuideElement
end

"""
    Guide.yrug

Draw short horizontal lines along the y-axis of a plot at the positions in the 'y' aesthetic.
"""
const yrug = YRug

function render(guide::YRug, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Guide.yrug", aes, :y)
    padding = 0.4mm

    ctx = compose!(context(minwidth=theme.rug_size, clip=true),
        line([[(0w + padding, y), (1w - padding, y)] for y in aes.y]),
        stroke(theme.default_color),
        linewidth(theme.line_width),
        svgclass("guide xfixed"))

    return [PositionedGuide([ctx], 20, right_guide_position)]
end


# Arrange a plot with its guides
#
# Args:
#   plot_canvas: A canvas containing the plot graphics.
#   guides: Tuples of guide canvases each with a GuidePosition giving
#           where the guide should be placed relative to the plot.
#
# Returns:
#   A new canvas containing the plot with guides layed out in the specified
#   manner.
function layout_guides(plot_context::Context,
                       coord::Gadfly.CoordinateElement,
                       theme::Gadfly.Theme,
                       positioned_guides::PositionedGuide...)
    # Organize guides by position
    guides = DefaultDict(() -> (Tuple{Vector{Context}, Int})[])
    for positioned_guide in positioned_guides
        push!(guides[positioned_guide.position],
              (positioned_guide.ctxs, positioned_guide.order))
    end

    for (position, ordered_guides) in guides
        if position == left_guide_position || position == top_guide_position
            sort!(ordered_guides, by=x -> x[2])
        else
            sort!(ordered_guides, by=x -> -x[2])
        end
    end

    m = 1 + length(guides[top_guide_position]) +
            length(guides[bottom_guide_position])
    n = 1 + length(guides[left_guide_position]) +
            length(guides[right_guide_position])

    focus_y = 1 + length(guides[top_guide_position])
    focus_x = 1 + length(guides[left_guide_position])

    plot_units = plot_context.units

    # Populate the table

    aspect_ratio = nothing
    if isa(coord, Gadfly.Coord.cartesian)
        if coord.fixed
            aspect_ratio = plot_context.units===nothing ? 1.0 :
                     abs(plot_context.units.width / plot_context.units.height)
        elseif coord.aspect_ratio != nothing
            aspect_ratio = coord.aspect_ratio
        end
    end
    tbl = table(m, n, focus_y:focus_y, focus_x:focus_x, units=plot_units,
                aspect_ratio=aspect_ratio)

    i = 1
    for (ctxs, order) in guides[top_guide_position]
        for ctx in ctxs
            if ctx.units===nothing && plot_units!==nothing
                ctx.units = UnitBox(plot_units, toppad=0mm, bottompad=0mm)
            end
        end

        tbl[i, focus_x] = ctxs
        i += 1
    end
    i += 1
    for (ctxs, order) in guides[bottom_guide_position]
        for ctx in ctxs
            if ctx.units===nothing && plot_units!==nothing
                ctx.units = UnitBox(plot_units, toppad=0mm, bottompad=0mm)
            end
        end

        tbl[i, focus_x] = ctxs
        i += 1
    end

    j = 1
    for (ctxs, order) in guides[left_guide_position]
        for ctx in ctxs
            if ctx.units===nothing && plot_units!==nothing
                ctx.units = UnitBox(plot_units, leftpad=0mm, rightpad=0mm)
            end
        end

        tbl[focus_y, j] = ctxs
        j += 1
    end
    j += 1
    for (ctxs, order) in guides[right_guide_position]
        for ctx in ctxs
            if ctx.units===nothing && plot_units!==nothing
                ctx.units = UnitBox(plot_units, leftpad=0mm, rightpad=0mm)
            end
        end

        tbl[focus_y, j] = ctxs
        j += 1
    end

    tbl[focus_y, focus_x] =
        [compose!(context(minwidth=minwidth(plot_context),
                          minheight=minheight(plot_context),
                          units=plot_units,
                          clip=true),
                  Any[context(order=-1),
                      [c for (c, o) in guides[under_guide_position]]...],
                  Any[context(order=1000),
                      [c for (c, o) in guides[over_guide_position]]...],
                  (context(order=0),
                     plot_context),
                  jscall("init_gadfly()"))]

    return tbl
end


struct Annotation <: Gadfly.GuideElement
    ctx::Context
end

"""
    Guide.annotation(ctx::Compose.Context)

Overlay a plot with an arbitrary `Compose` graphic. The context will inherit
the plot's coordinate system, unless overridden with a custom unit box.
"""
const annotation = Annotation

function render(guide::Annotation, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    ctx = compose(context(), svgclass("geometry"), guide.ctx)
    return [PositionedGuide([ctx], 0, over_guide_position)]
end


include("guide/keys.jl")


end # module Guide
