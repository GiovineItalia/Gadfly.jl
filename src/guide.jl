
module Guide

using Color
using Compose
using Gadfly
using JSON

import Gadfly.render, Gadfly.escape_id


# Where the guide should be placed in relation to the plot.
abstract GuidePosition
immutable TopGuidePosition    <: GuidePosition end
immutable RightGuidePosition  <: GuidePosition end
immutable BottomGuidePosition <: GuidePosition end
immutable LeftGuidePosition   <: GuidePosition end
immutable UnderGuidePosition  <: GuidePosition end

const top_guide_position    = TopGuidePosition()
const right_guide_position  = RightGuidePosition()
const bottom_guide_position = BottomGuidePosition()
const left_guide_position   = LeftGuidePosition()
const under_guide_position  = UnderGuidePosition()


immutable PanelBackground <: Gadfly.GuideElement
end

const background = PanelBackground


function render(guide::PanelBackground, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    back = compose(canvas(order=-1),
                   rectangle(),
                   svgclass("guide background"),
                   stroke(theme.panel_stroke),
                   fill(theme.panel_fill))

    {(back, under_guide_position)}
end


immutable ColorKey <: Gadfly.GuideElement
end


const colorkey = ColorKey


# A helper for render(::ColorKey) for rendering guides for discrete color
# scales.
function render_discrete_color_key(colors::Vector{ColorValue},
                                   labels::Dict{ColorValue, String},
                                   title_canvas::Canvas,
                                   title_width::Measure,
                                   theme::Gadfly.Theme)
    # Key entries
    n = length(colors)

    entry_width, entry_height = text_extents(theme.minor_label_font,
                                             theme.minor_label_font_size,
                                             values(labels)...)
    entry_width += entry_height # make space for the color swatch

    # Rewrite to put toggleable things in a group.
    swatch_padding = 1mm
    swatch_size = 1cy - swatch_padding
    swatch_canvas = canvas(0w, 0h + title_canvas.box.height,
                           1w, n * (entry_height + swatch_padding),
                           unit_box=Units(0, 0, 1, n))
    for (i, c) in enumerate(colors)
        swatch_square = compose(rectangle(0, i - 1, swatch_size, swatch_size),
                                fill(c),
                                stroke(theme.highlight_color(c)),
                                linewidth(theme.highlight_width))

        label = labels[c]
        swatch_label = compose(text(1cy, (i - 1)cy + entry_height/2,
                                    label, hleft, vcenter),
                               stroke(nothing),
                               fill(theme.minor_label_color))
        swatch = swatch_square | swatch_label

        color_class = @sprintf("color_%s", escape_id(label))
        swatch <<= svgclass(@sprintf("guide %s", color_class))

        swatch <<= d3embed(
            @sprintf(".on(\"click\", guide_toggle_color(parent_id, \"%s\"))",
                     color_class))

        swatch_canvas <<= swatch
    end
    swatch_canvas <<= font(theme.minor_label_font) |
                      fontsize(theme.minor_label_font_size)
    c = canvas(0, 0, max(title_width, entry_width) + 3swatch_padding,
               swatch_canvas.box.height + title_canvas.box.height) <<
        pad(canvas() << swatch_canvas << title_canvas, 2mm)
    c
end


# A helper for render(::ColorKey) for rendering guides for continuous color
# scales.
function render_continuous_color_key(colors::Vector{ColorValue},
                                   labels::Dict{ColorValue, String},
                                   title_canvas::Canvas,
                                   title_width::Measure,
                                   theme::Gadfly.Theme)

    # Key entries
    entry_width, entry_height = text_extents(theme.minor_label_font,
                                             theme.minor_label_font_size,
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

            swatch_canvas <<= swatch_square

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
                                   fill(theme.minor_label_color))

            swatch_canvas <<= swatch_square | swatch_label

            y += entry_height
        end
    end

    swatch_canvas <<= font(theme.minor_label_font) |
                      fontsize(theme.minor_label_font_size) |
                      stroke(nothing)

    c = canvas(0, 0, max(title_width, entry_width) + 3swatch_padding,
               swatch_canvas.box.height + title_canvas.box.height) <<
        pad(canvas() << swatch_canvas << title_canvas, 2mm)
    c
end


function render(guide::ColorKey, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    used_colors = Set{ColorValue}()
    colors = Array(ColorValue, 0) # to preserve ordering
    labels = Dict{ColorValue, Set{String}}()

    continuous_guide = false
    guide_title = nothing

    for aes in aess
        if guide_title === nothing && !is(aes.color_key_title, nothing)
            guide_title = aes.color_key_title
        end

        if aes.color_key_colors === nothing
            continue
        end

        if !is(aes.color_key_continuous, nothing) && aes.color_key_continuous
            continuous_guide = true
        end

        for color in aes.color_key_colors
            label = aes.color_label(color)
            if !contains(used_colors, color)
                add!(used_colors, color)
                push!(colors, color)
                labels[color] = Set{String}(label)
            else
                add!(labels[color], label)
            end
        end
    end

    if guide_title === nothing
        guide_title = ""
    end

    pretty_labels = Dict{ColorValue, String}()
    for (color, label) in labels
        pretty_labels[color] = join(labels[color], ", ")
    end

    # Key title
    title_width, title_height = text_extents(theme.major_label_font,
                                             theme.major_label_font_size,
                                             guide_title)

    title_padding = 2mm
    title_canvas = compose(canvas(0w, 0h, 1w, title_height + title_padding),
                           text(0.5w, title_height, guide_title, hcenter, vbottom),
                           stroke(nothing),
                           font(theme.major_label_font),
                           fontsize(theme.major_label_font_size),
                           fill(theme.major_label_color))

    if continuous_guide
        c = render_continuous_color_key(colors, pretty_labels, title_canvas,
                                        title_width, theme)
    else
        c = render_discrete_color_key(colors, pretty_labels, title_canvas,
                                      title_width, theme)
    end

    {(c, right_guide_position)}
end


immutable XTicks <: Gadfly.GuideElement
    label::Bool

    function XTicks(label::Bool=true)
        new(label)
    end
end

const x_ticks = XTicks


function render(guide::XTicks, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})

    ticks = Dict{Float64, String}()
    grids = Set()
    for aes in aess
        if Gadfly.issomething(aes.xtick)
            for val in aes.xtick
                ticks[val] = aes.xtick_label(val)
            end
        end

        if Gadfly.issomething(aes.xgrid)
            for val in aes.xgrid
                add!(grids, val)
            end
        end
    end

    # grid lines
    grid_lines = compose(canvas(),
                         [lines((t, 0h), (t, 1h)) for t in grids]...,
                         stroke(theme.grid_color),
                         linewidth(theme.grid_line_width),
                         svgclass("guide xgridlines"))

    if !guide.label
        return {(grid_lines, under_guide_position)}
    end

    # tick labels

    (_, height) = text_extents(theme.minor_label_font,
                               theme.minor_label_font_size,
                               values(ticks)...)
    #padding = 1mm
    padding = 0mm

    tick_labels = compose(canvas(0, 0, 1w, height + 2padding, order=-1),
                          [text(tick, 1h - padding, label, hcenter, vbottom)
                           for (tick, label) in ticks]...,
                          stroke(nothing),
                          fill(theme.minor_label_color),
                          font(theme.minor_label_font),
                          fontsize(theme.minor_label_font_size),
                          svgclass("guide xlabels"))

    {(grid_lines, under_guide_position),
     (tick_labels, bottom_guide_position)}
end


immutable YTicks <: Gadfly.GuideElement
    label::Bool

    function YTicks(label::Bool=true)
        new(label)
    end
end

const y_ticks = YTicks

function render(guide::YTicks, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    ticks = Dict{Float64, String}()
    grids = Set()
    for aes in aess
        if Gadfly.issomething(aes.ytick)
            for val in aes.ytick
                ticks[val] = aes.ytick_label(val)
            end
        end

        if Gadfly.issomething(aes.ygrid)
            for val in aes.ygrid
                add!(grids, val)
            end
        end
    end

    # grid lines
    grid_lines = compose(canvas(),
                         [lines((0w, t), (1w, t)) for t in grids]...,
                         stroke(theme.grid_color),
                         linewidth(theme.grid_line_width),
                         svgclass("guide ygridlines"))

    if !guide.label
        return {(grid_lines, under_guide_position)}
    end

    # tick labels
    (width, _) = text_extents(theme.minor_label_font,
                              theme.minor_label_font_size,
                              values(ticks)...)
    padding = 1mm
    width += 2padding

    tick_labels = compose(canvas(0, 0, width, 1cy, order=-1),
                          [text(width - padding, t, label, hright, vcenter)
                           for (t, label) in ticks]...,
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
    label::String
end

const x_label = XLabel


function render(guide::XLabel, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
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

    {(c, bottom_guide_position)}
end


# Y-axis label Guide
immutable YLabel <: Gadfly.GuideElement
    label::String
end

const y_label = YLabel

function render(guide::YLabel, theme::Gadfly.Theme, aess::Vector{Gadfly.Aesthetics})
    (text_width, text_height) = text_extents(theme.major_label_font,
                                             theme.major_label_font_size,
                                             guide.label)
    padding = 1mm
    c = compose(canvas(0, 0, text_height + 2padding, 1cy,
                       rotation=Rotation(-0.5pi, 0.5w, 0.5h)),
                text(0.5w, 0.5h, guide.label, hcenter, vcenter),
                stroke(nothing),
                fill(theme.major_label_color),
                font(theme.major_label_font),
                fontsize(theme.major_label_font_size))

    {(c, left_guide_position)}
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
function layout_guides(plot_canvas::Canvas,
                       theme::Gadfly.Theme,
                       guides::(Canvas, GuidePosition)...;
                       preserve_plot_canvas_size=false)

    # Every guide is updated to use the plot's unit box.
    guides = [(set_unit_box(guide, plot_canvas.unit_box), pos)
              for (guide, pos) in guides]

    # Group by position
    top_guides    = Canvas[]
    right_guides  = Canvas[]
    bottom_guides = Canvas[]
    left_guides   = Canvas[]
    under_guides  = Canvas[]
    for (guide, pos) in guides
        if pos === top_guide_position
            push!(top_guides, guide)
        elseif pos === right_guide_position
            push!(right_guides, guide)
        elseif pos === bottom_guide_position
            push!(bottom_guides, guide)
        elseif pos === left_guide_position
            push!(left_guides, guide)
        elseif pos === under_guide_position
            push!(under_guides, guide)
        end
    end

    # Since top/right/bottom/left guides are drawn without overlaps, we use the
    # canvas z-order to determine ordering, with lowest ordered guides placed
    # nearest to the panel.
    canvas_order = canvas -> canvas.order
    rev_canvas_order = canvas -> -canvas.order
    sort!(by=canvas_order,     top_guides)
    sort!(by=canvas_order,     right_guides)
    sort!(by=canvas_order,     bottom_guides)
    sort!(by=rev_canvas_order, left_guides)

    # Stack the guides on edge edge of the plot
    top_guides    = vstack(0, 0, 1, [(g, hcenter) for g in top_guides]...)
    right_guides  = hstack(0, 0, 1, [(g, vcenter) for g in right_guides]...)
    bottom_guides = vstack(0, 0, 1, [(g, hcenter) for g in bottom_guides]...)
    left_guides   = hstack(0, 0, 1, [(g, vcenter) for g in left_guides]...)

    # Reposition each guide stack, now that we know the extents
    t = top_guides.box.height
    r = right_guides.box.width
    b = bottom_guides.box.height
    l = left_guides.box.width

    pw = 1cx - l - r # plot width
    ph = 1cy - t - b # plot height

    top_guides    = set_box(top_guides,    BoundingBox(l, 0, pw, t))
        # TODO: clip path

    right_guides  = set_box(right_guides,  BoundingBox(l + pw, t, r, ph))
        # TODO: clip path

    bottom_guides = set_box(bottom_guides, BoundingBox(l, t + ph, pw, b)) <<
                      clip((0cx, 1cy - b), (1cx, 1cy - b),
                           (1cx, 1cy), (0cx, 1cy))

    left_guides   = set_box(left_guides,   BoundingBox(0, t, l, ph)) <<
                      clip((0cx, 0cy), (0cx + l, 0cy),
                           (0cx + l, 1cy), (0cx, 1cy))

    root_canvas = preserve_plot_canvas_size ?
        canvas(0, 0, 1.0w + l + r, 1.0h + t + b) : canvas()

    compose(root_canvas,
            (canvas(l, t, pw, ph),
                {canvas(units_inherited=true, order=-1, clip=true), under_guides...},
                (canvas(units_inherited=true, order=1, clip=true),  plot_canvas),
                d3embed(@sprintf(
                    ".on(\"mouseover\", guide_background_mouseover(parent_id, %s))",
                    json(theme.highlight_color(theme.grid_color)))),
                d3embed(@sprintf(
                    ".on(\"mouseout\", guide_background_mouseout(parent_id, %s))",
                    json(theme.grid_color))),
                d3embed(".call(zoom_behavior(parent_id, t))")),
            top_guides, right_guides, bottom_guides, left_guides)
end

end # module Guide

