
module Guide

using Color
using Compose
using DataStructures
using Gadfly
using Iterators
using JSON

import Gadfly: render, escape_id, default_statistic


# Where the guide should be placed in relation to the plot.
abstract GuidePosition
immutable TopGuidePosition    <: GuidePosition end
immutable RightGuidePosition  <: GuidePosition end
immutable BottomGuidePosition <: GuidePosition end
immutable LeftGuidePosition   <: GuidePosition end
immutable UnderGuidePosition  <: GuidePosition end
immutable OverGuidePosition   <: GuidePosition end

const top_guide_position    = TopGuidePosition()
const right_guide_position  = RightGuidePosition()
const bottom_guide_position = BottomGuidePosition()
const left_guide_position   = LeftGuidePosition()
const under_guide_position  = UnderGuidePosition()
const over_guide_position   = OverGuidePosition()


# A guide graphic is a position associated with one or more contexts.
# Multiple contexts represent multiple layout possibilites that will be
# optimized over.
immutable PositionedGuide
    ctxs::Vector{Context}
    order::Int
    position::GuidePosition
end


immutable PanelBackground <: Gadfly.GuideElement
end

const background = PanelBackground


function render(guide::PanelBackground, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    back = compose!(context(order=-1),
                    rectangle(),
                    svgclass("guide background"),
                    stroke(theme.panel_stroke),
                    fill(theme.panel_fill),
                    fillopacity(theme.panel_opacity))

    return [PositionedGuide([back], 0, under_guide_position)]
end


immutable ZoomSlider <: Gadfly.GuideElement
end

const zoomslider = ZoomSlider


# TODO: rewrite
function render(guide::ZoomSlider, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)

    edge_pad = 3mm
    slide_pad = 0.5mm
    button_size = 4mm
    slider_size = 20mm
    background_color = "#eaeaea"
    foreground_color = "#6a6a6a"
    highlight_color = "#cd5c5c";

    minus_button = compose(canvas(1w - edge_pad - 2*button_size - slider_size,
                                  edge_pad, button_size, button_size),
                           rectangle(),
                             stroke(foreground_color),
                             strokeopacity(0.0),
                             linewidth(0.3mm),
                           (polygon((0.2, 0.4), (0.8, 0.4),
                                    (0.8, 0.6), (0.2, 0.6)),
                            fill(foreground_color),
                            svgclass("button_logo")),
                           fill(background_color),
                           d3embed(
                               """
                               .on("click", zoomout_behavior(ctx))
                               .on("dblclick", function() { d3.event.stopPropagation(); })
                               .on("mouseover", zoomslider_button_mouseover("$(highlight_color)"))
                               .on("mouseout", zoomslider_button_mouseover("$(foreground_color)"))
                               """))

    slider_width = 2mm
    slider_xpos = 1w - edge_pad - button_size - slider_size + slide_pad

    slider_min_pos = slider_xpos + slider_width/2
    slider_max_pos = slider_xpos + slider_size - 2*slide_pad - slider_width/2

    slider = compose(canvas(slider_xpos,
                            edge_pad, slider_size - 2 * slide_pad, button_size),
                     (rectangle(),
                      fill(background_color),
                      d3embed(".on(\"click\", zoomslider_track_behavior(ctx, %x, %x))",
                              slider_min_pos, slider_max_pos)),
                     (rectangle(0.5cx - slider_width/2, 0.0, slider_width, 1h),
                      fill(foreground_color),
                      svgclass("zoomslider_thumb"),
                      d3embed(
                        """
                        .call(zoomslider_behavior(ctx, %x, %x))
                        .on("mouseover", zoomslider_thumb_mouseover("$(highlight_color)"))
                        .on("mouseout", zoomslider_thumb_mouseover("$(foreground_color)"))
                        """,
                        slider_min_pos, slider_max_pos)))


    plus_button = compose(canvas(1w - edge_pad - button_size, edge_pad,
                                    button_size, button_size),
                          rectangle(),
                            stroke(foreground_color),
                            strokeopacity(0.0),
                            linewidth(0.3mm),
                          (polygon((0.2, 0.4), (0.4, 0.4), (0.4, 0.2),
                                   (0.6, 0.2), (0.6, 0.4), (0.8, 0.4),
                                   (0.8, 0.6), (0.6, 0.6), (0.6, 0.8),
                                   (0.4, 0.8), (0.4, 0.6), (0.2, 0.6)),
                           fill(foreground_color),
                           svgclass("button_logo")),
                          fill(background_color),
                          d3embed(
                              """
                              .on("click", zoomin_behavior(ctx))
                              .on("dblclick", function() { d3.event.stopPropagation(); })
                              .on("mouseover", zoomslider_button_mouseover("$(highlight_color)"))
                              .on("mouseout", zoomslider_button_mouseover("$(foreground_color)"))
                              """))

    root = compose(canvas(d3only=true),
                   minus_button,
                   slider,
                   plus_button,
                   stroke(nothing),
                   #stroke(foreground_color),
                   svgclass("guide zoomslider"),
                   opacity(0.0))

    {(root, over_guide_position)}
end


immutable ColorKey <: Gadfly.GuideElement
    title::Union(String, Nothing)

    function ColorKey(title=nothing)
        new(title)
    end
end


const colorkey = ColorKey


# TODO: rewrite
# A helper for render(::ColorKey) for rendering guides for discrete color
# scales.
function render_discrete_color_key(colors::Vector{ColorValue},
                                   labels::Dict{ColorValue, String},
                                   title_context::Context,
                                   title_width::Measure,
                                   theme::Gadfly.Theme)
    # Key entries
    n = length(colors)

    entry_width, entry_height = text_extents(theme.key_label_font,
                                             theme.key_label_font_size,
                                             values(labels)...)
    entry_width += entry_height # make space for the color swatch

    # Rewrite to put toggleable things in a group.
    swatch_padding = 1mm
    swatch_size = 1cy - swatch_padding
    swatch_canvas = canvas(0w, 0h + title_canvas.box.height,
                           1w, n * (entry_height + swatch_padding),
                           unit_box=UnitBox(0, 0, 1, n))
    for (i, c) in enumerate(colors)
        if theme.colorkey_swatch_shape == :square
            swatch_shape = rectangle(0, i - 1, swatch_size, swatch_size)
        elseif theme.colorkey_swatch_shape == :circle
            swatch_shape = circle(0.5cy, (i - 1)cy + entry_height/2, swatch_size/2)
        end

        swatch_shape = compose(swatch_shape,
                               fill(c),
                               stroke(theme.highlight_color(c)),
                               linewidth(theme.highlight_width))

        label = labels[c]
        swatch_label = compose(text(1cy, (i - 1)cy + entry_height/2,
                                    label, hleft, vcenter),
                               stroke(nothing),
                               fill(theme.key_label_color))

        color_class = @sprintf("color_%s", escape_id(label))
        swatch = compose(combine(swatch_shape, swatch_label),
                         svgclass(@sprintf("guide %s", color_class)),
                         d3embed(@sprintf(
                            ".on(\"click\", guide_toggle_color(\"%s\"))",
                            color_class)))
        swatch_canvas = compose(swatch_canvas, swatch)
    end

    swatch_canvas = compose(swatch_canvas,
                            font(theme.key_label_font),
                            fontsize(theme.key_label_font_size))

    title_canvas_pos = theme.guide_title_position == :left ?
        entry_height + swatch_padding : 0
    title_canvas = compose(canvas(title_canvas_pos, 0h, 1w,
                                  title_canvas.box.height),
                           title_canvas)

    compose(canvas(0, 0, max(title_width, entry_width) + 3swatch_padding,
                   swatch_canvas.box.height + title_canvas.box.height, order=2),
            pad(compose(canvas(), swatch_canvas, title_canvas), 2mm))
end


# TODO: rewrite
# A helper for render(::ColorKey) for rendering guides for continuous color
# scales.
function render_continuous_color_key(colors::Vector{ColorValue},
                                     labels::Dict{ColorValue, String},
                                     title_context::Context,
                                     title_width::Measure,
                                     theme::Gadfly.Theme)

    # Key entries
    entry_width, entry_height = text_extents(theme.key_label_font,
                                             theme.key_label_font_size,
                                             values(labels)...)
    entry_width += entry_height # make space for the color swatch

    unlabeled_swatches = 0
    for c in colors
        if labels[c] == ""
            unlabeled_swatches += 1
        end
    end

    unlabeled_swatch_height = 1.0mm
    swatch_padding = 1mm

    swatch_canvas = canvas(0w, 0h + title_canvas.box.height, 1w,
                           unlabeled_swatches * unlabeled_swatch_height +
                           (length(colors) - unlabeled_swatches) * entry_height)

    # Nudge things to overlap slightly avoiding any gaps.
    nudge = 0.1mm

    y = 0cy
    for (i, c) in enumerate(colors)
        if labels[c] == ""
            swatch_square = compose(rectangle(0, y,
                                              entry_height,
                                              unlabeled_swatch_height + nudge),
                                    fill(c),
                                    linewidth(theme.highlight_width))

            swatch_canvas = compose(swatch_canvas, swatch_square)

            y += unlabeled_swatch_height
        else
            swatch_square = compose(rectangle(0, y,
                                              entry_height,
                                              entry_height + nudge),
                                    fill(c),
                                    linewidth(theme.highlight_width))
            swatch_label = compose(text(entry_height + swatch_padding,
                                        y + entry_height / 2,
                                        labels[c],
                                        hleft, vcenter),
                                   fill(theme.key_label_color))

            swatch_canvas = compose(swatch_canvas, swatch_square, swatch_label)

            y += entry_height
        end
    end

    swatch_canvas = compose(swatch_canvas,
                            font(theme.key_label_font),
                            fontsize(theme.key_label_font_size),
                            stroke(nothing))

    title_canvas_pos = theme.guide_title_position == :left ?
        entry_height + swatch_padding : 0
    title_canvas = compose(canvas(title_canvas_pos, 0h, 1w,
                                  title_canvas.box.height),
                           title_canvas)

    compose(canvas(0, 0, max(title_width, entry_width) + 3swatch_padding,
                   swatch_canvas.box.height + title_canvas.box.height, order=2),
            pad(compose(canvas(), swatch_canvas, title_canvas), 2mm))
end


# TODO: rewrite
function render(guide::ColorKey, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)

    if theme.key_position == :none
        return nothing
    else
        used_colors = Set{ColorValue}()
        colors = Array(ColorValue, 0) # to preserve ordering
        labels = Dict{ColorValue, Set{String}}()

        continuous_guide = false
        guide_title = guide.title

        if guide_title === nothing && !is(aes.color_key_title, nothing)
            guide_title = aes.color_key_title
        end

        if aes.color_key_colors != nothing &&
           aes.color_key_continuous != nothing &&
           aes.color_key_continuous
            continuous_guide = true
        end

        color_key_labels = aes.color_label(aes.color_key_colors)
        for (color, label) in zip(aes.color_key_colors, color_key_labels)
            if !in(color, used_colors)
                push!(used_colors, color)
                push!(colors, color)
                labels[color] = Set{String}()
                push!(labels[color], label)
            else
                push!(labels[color], label)
            end
        end

        if guide_title === nothing
            guide_title = "Color"
        end

        pretty_labels = Dict{ColorValue, String}()
        for (color, label) in labels
            pretty_labels[color] = join(labels[color], ", ")
        end

        # Key title
        title_width, title_height = text_extents(theme.key_title_font,
                                             theme.key_title_font_size,
                                             guide_title)

        if theme.guide_title_position == :left
            title_form = text(0.0w, title_height, guide_title, hleft, vbottom)
        elseif theme.guide_title_position == :center
            title_form = text(0.5w, title_height, guide_title, hcenter, vbottom)
        elseif theme.guide_title_position == :right
            title_form = text(1.0w, title_height, guide_title, hright, vbottom)
        else
            error("$(theme.guide_title_position) is not a valid guide title position")
        end

        title_padding = 2mm
        title_canvas = compose(canvas(0w, 0h, 1w, title_height + title_padding),
                           title_form,
                           stroke(nothing),
                           font(theme.key_title_font),
                           fontsize(theme.key_title_font_size),
                           fill(theme.key_title_color))

        if theme.colorkey_swatch_shape != :circle &&
        theme.colorkey_swatch_shape != :square
            error("$(theme.colorkey_swatch_shape) is not a valid color key swatch shape")
        end

        if continuous_guide
            c = render_continuous_color_key(colors, pretty_labels, title_canvas,
                                        title_width, theme)
        else
            c = render_discrete_color_key(colors, pretty_labels, title_canvas,
                                      title_width, theme)
        end

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

        return {(c, position)}
    end
end


immutable XTicks <: Gadfly.GuideElement
    label::Bool
    ticks::Union(Nothing, AbstractArray)

    function XTicks(; label::Bool=true,
                      ticks::Union(Nothing, AbstractArray)=nothing)
        new(label, ticks)
    end
end

const xticks = XTicks


function default_statistic(guide::XTicks)
    Stat.xticks(guide.ticks)
end


function render(guide::XTicks, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    ticks = Dict()
    grids = Set()

    if Gadfly.issomething(aes.xtick)
        for (val, label) in zip(aes.xtick, aes.xtick_label(aes.xtick))
            ticks[val] = label
        end
    end

    if Gadfly.issomething(aes.xgrid)
        for val in aes.xgrid
            push!(grids, val)
        end
    end

    viewmin, viewmax = nothing, nothing
    if (viewmin != nothing && aes.xviewmin != nothing && aes.xviewmin < viewmin) ||
       (viewmin == nothing && aes.xviewmin != nothing)
        viewmin = aes.xviewmin
    end
    if (viewmax != nothing && aes.xviewmax != nothing && aes.xviewmax > viewmax) ||
       (viewmax == nothing && aes.xviewmax != nothing)
        viewmax = aes.xviewmax
    end

    # grid lines
    grid_lines = compose!(context(),
                          lines([[(t, 0h), (t, 1h)] for t in grids]...),
                          stroke(theme.grid_color),
                          linewidth(theme.grid_line_width),
                          svgclass("guide xgridlines yfixed"))

    if !guide.label
        return [PositionedGuide([grid_lines], 0, under_guide_position)]
    end


    label_sizes = text_extents(theme.minor_label_font,
                               theme.minor_label_font_size,
                               values(ticks)...)
    label_widths = [width for (width, height) in label_sizes]
    label_heights = [height for (width, height) in label_sizes]

    padding = 1mm

    hlayout = ctxpromise() do draw_context
        return compose!(context(),
                        text([tick for (tick, label) in ticks],
                             [1h - padding],
                             [label for (tick, label) in ticks],
                             [hcenter], [vbottom]),
                        fill(theme.minor_label_color),
                        font(theme.minor_label_font),
                        fontsize(theme.minor_label_font_size),
                        svgclass("guide xlabels"))
    end
    hlayout_context = compose!(context(minwidth=sum(label_widths),
                                       minheight=maximum(label_heights)),
                               hlayout)

    vlayout = ctxpromise() do draw_context
        return compose!(context(),
                        text([tick for (tick, label) in ticks],
                             [1h - padding],
                             [lobel for (tick, label) in ticks],
                             [hright], [vbottom], [Rotation(270)]),
                        fill(theme.minor_label_color),
                        font(theme.minor_label_font),
                        fontsize(theme.minor_label_font_size),
                        svgclass("guide xlabels"))
    end
    vlayout_context = compose!(context(minwidth=sum(label_heights),
                                       minheight=maximum(label_widths)),
                               vlayout)

    return [PositionedGuide([hlayout_context, vlayout_context], 0,
                            bottom_guide_position),
            PositionedGuide([grid_lines], 0, under_guide_position)]
end


immutable YTicks <: Gadfly.GuideElement
    label::Bool
    ticks::Union(Nothing, AbstractArray)

    function YTicks(; label::Bool=true,
                      ticks::Union(Nothing, AbstractArray)=nothing)
        new(label, ticks)
    end
end


const yticks = YTicks


function default_statistic(guide::YTicks)
    Stat.yticks(guide.ticks)
end


function render(guide::YTicks, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    ticks = Dict()
    grids = Set()

    if Gadfly.issomething(aes.ytick)
        for (val, label) in zip(aes.ytick, aes.ytick_label(aes.ytick))
            ticks[val] = label
        end
    end

    if Gadfly.issomething(aes.ygrid)
        for val in aes.ygrid
            push!(grids, val)
        end
    end

    viewmin, viewmax = nothing, nothing
    if (viewmin != nothing && aes.yviewmin != nothing && aes.yviewmin < viewmin) ||
       (viewmin == nothing && aes.yviewmin != nothing)
        viewmin = aes.yviewmin
    end
    if (viewmax != nothing && aes.yviewmax != nothing && aes.yviewmax > viewmax) ||
       (viewmax == nothing && aes.yviewmax != nothing)
        viewmax = aes.yviewmax
    end

    # grid lines
    grid_lines = compose(canvas(),
                         [lines((0w, t), (1w, t)) for t in grids]...,
                         stroke(theme.grid_color),
                         linewidth(theme.grid_line_width),
                         svgclass("guide ygridlines xfixed"))

    if !guide.label
        return {(grid_lines, under_guide_position)}
    end

    # tick labels
    (width, _) = text_extents(theme.minor_label_font,
                              theme.minor_label_font_size,
                              values(ticks)...)
    padding = 1mm
    width += 2padding

    texts = Array(Canvas, length(ticks))
    for (i, (tick, label)) in enumerate(ticks)
        txt = text(width - padding, tick, label, hright, vcenter)
        if (viewmin != nothing && viewmax != nothing) && viewmin <= tick <= viewmax
            texts[i] = compose(canvas(), txt)
        else
            texts[i] = compose(canvas(d3only=true), txt,
                               d3embed(""".attr("visibility", "hidden")"""))
        end
    end

    tick_labels = compose(canvas(0, 0, width, 1cy, order=-1),
                          texts...,
                          stroke(nothing),
                          fill(theme.minor_label_color),
                          font(theme.minor_label_font),
                          fontsize(theme.minor_label_font_size),
                          svgclass("guide ylabels"))

    {(grid_lines, under_guide_position),
     (tick_labels, left_guide_position)}
end


# X-axis label Guide
immutable XLabel <: Gadfly.GuideElement
    label::Union(Nothing, String)
end

const xlabel = XLabel


function render(guide::XLabel, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    if guide.label === nothing || isempty(guide.label)
        return nothing
    end

    text_width, text_height = max_text_extents(theme.major_label_font,
                                               theme.major_label_font_size,
                                               guide.label)

    padding = 2mm
    c = compose!(context(0, 0, 1w, text_height + 2padding,
                         minwidth=text_width + 2padding,
                         minheight=text_height + 2padding),
                 text(0.5w, 1h - padding, guide.label, hcenter, vbottom),
                 stroke(nothing),
                 fill(theme.major_label_color),
                 font(theme.major_label_font),
                 fontsize(theme.major_label_font_size))

    return [PositionedGuide([c], 0, bottom_guide_position)]
end


# Y-axis label Guide
immutable YLabel <: Gadfly.GuideElement
    label::Union(Nothing, String)
end

const ylabel = YLabel

function render(guide::YLabel, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    if guide.label === nothing || isempty(guide.label)
        return nothing
    end

    text_width, text_height = max_text_extents(theme.major_label_font,
                                               theme.major_label_font_size,
                                               guide.label)
    padding = 1mm
    c = compose(context(0, 0, text_height + 2padding, 1cy,
                       rotation=Rotation(-0.5pi, 0.5w, 0.5h),
                       minwidth=text_height + 2padding,
                       minheight=text_width + 2padding),
                text(0.5w, 0.5h, guide.label, hcenter, vcenter),
                stroke(nothing),
                fill(theme.major_label_color),
                font(theme.major_label_font),
                fontsize(theme.major_label_font_size))

    return [PositionedGuide([c], 0, left_guide_position)]
end

# Title Guide
immutable Title <: Gadfly.GuideElement
    label::Union(Nothing, String)
end

const title = Title

function render(guide::Title, theme::Gadfly.Theme,
                aes::Gadfly.Aesthetics)
    if guide.label === nothing || isempty(guide.label)
        return nothing
    end

    (_, text_height) = text_extents(theme.major_label_font,
                                    theme.major_label_font_size,
                                    guide.label)

    padding = 2mm
    c = compose(canvas(0, 0, 1w, text_height + 2padding),
                text(0.5w, 1h - padding, guide.label, hcenter, vbottom),
                stroke(nothing),
                fill(theme.major_label_color),
                font(theme.major_label_font),
                fontsize(theme.major_label_font_size))

    {(c, top_guide_position)}
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
                       theme::Gadfly.Theme,
                       positioned_guides::PositionedGuide...)
    # Organize guides by position
    guides = DefaultDict(() -> (Vector{Context}, Int)[])
    for positioned_guide in positioned_guides
        push!(guides[positioned_guide.position],
              (positioned_guide.ctxs, positioned_guide.order))
    end

    for (position, ordered_guides) in guides
        if position == left_guide_position
            sort!(ordered_guides, by=x -> -x[2])
        else
            sort!(ordered_guides, by=x -> x[2])
        end
    end

    m = 1 + length(guides[top_guide_position]) +
            length(guides[bottom_guide_position])
    n = 1 + length(guides[left_guide_position]) +
            length(guides[right_guide_position])

    focus = (1 + length(guides[top_guide_position]),
             1 + length(guides[left_guide_position]))

    # Populate the table
    tbl = table(m, n, focus, units=plot_context.units)

    i = 1
    for (ctxs, order) in guides[top_guide_position]
        tbl[i, focus[2]] = ctxs
        i += 1
    end
    i += 1
    for (ctxs, order) in guides[bottom_guide_position]
        tbl[i, focus[2]] = ctxs
        i += 1
    end

    j = 1
    for (ctxs, order) in guides[left_guide_position]
        tbl[focus[1], j] = ctxs
        j += 1
    end
    j += 1
    for (ctxs, order) in guides[right_guide_position]
        tbl[focus[1], j] = ctxs
        j += 1
    end

    tbl[focus[1], focus[2]] =
        [compose!(context(minwidth=minwidth(plot_context),
                          minheight=minheight(plot_context)),
                  {context(order=-1),
                     [c for (c, o) in guides[under_guide_position]]...},
                  {context(order=1000),
                     [c for (c, o) in guides[over_guide_position]]...},
                  {context(order=0),
                     plot_context})]

    return compose!(context(), tbl)
end

end # module Guide

