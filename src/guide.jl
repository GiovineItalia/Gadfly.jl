
module Guide

using Gadfly
using Compose

import Gadfly.render


# Where the guide should be placed in relation to the plot.
abstract GuidePosition
type TopGuidePosition    <: GuidePosition end
type RightGuidePosition  <: GuidePosition end
type BottomGuidePosition <: GuidePosition end
type LeftGuidePosition   <: GuidePosition end
type UnderGuidePosition  <: GuidePosition end

const top_guide_position    = TopGuidePosition()
const right_guide_position  = RightGuidePosition()
const bottom_guide_position = BottomGuidePosition()
const left_guide_position   = LeftGuidePosition()
const under_guide_position  = UnderGuidePosition()


type PanelBackground <: Gadfly.GuideElement
end

const background = PanelBackground()


function render(guide::PanelBackground, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    c = compose(canvas(), rectangle(),
                stroke(theme.panel_stroke),
                fill(theme.panel_fill))
    {(c, under_guide_position)}
end


type ColorKey <: Gadfly.GuideElement
end


const colorkey = ColorKey()


function render(guide::ColorKey, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    used_colors = Set{Color}()
    colors = Array(Color, 0) # to preserve ordering
    labels = Dict{Color, Set{String}}()

    guide_title = nothing

    for aes in aess
        if guide_title === nothing && !is(aes.color_key_title, nothing)
            guide_title = aes.color_key_title
        end

        if aes.color_key_colors === nothing
            continue
        end

        for color in aes.color_key_colors
            label = aes.color_label(color)
            if !has(used_colors, color)
                add(used_colors, color)
                push!(colors, color)
                labels[color] = Set{String}(label)
            else
                add(labels[color], label)
            end
        end
    end

    if guide_title === nothing
        guide_title = ""
    end

    pretty_labels = Dict{Color, String}()
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

    # Key entries
    n = length(colors)

    entry_width, entry_height = text_extents(theme.minor_label_font,
                                             theme.minor_label_font_size,
                                             values(pretty_labels)...)
    entry_width += entry_height # make space for the color swatch

    # Rewrite to put toggleable things in a group.
    swatch_padding = 1mm
    swatch_size = 1cy - swatch_padding
    swatch_canvas = canvas(0w, 0h + title_canvas.box.height,
                           1w, n * (entry_height + swatch_padding),
                           Units(0, 0, 1, n))
    for (i, c) in enumerate(colors)
        swatch_square = compose(rectangle(0, i - 1, swatch_size, swatch_size),
                                fill(c),
                                stroke(theme.highlight_color(c)),
                                linewidth(theme.highlight_width))

        label = pretty_labels[c]
        swatch_label = compose(text(1cy, (i - 1)cy + entry_height/2,
                                    label, hleft, vcenter),
                               stroke(nothing),
                               fill(theme.minor_label_color))
        swatch = swatch_square | swatch_label

        swatch <<= svgid(@sprintf("color_key_%s", label))
        swatch <<= onclick(
            @sprintf("geoms = document.getElementsByClassName('color_group_%s');
                      entry = document.getElementById('color_key_%s');
                      state = geoms[0].getAttribute('visibility');
                      if (!state || state == 'visible') {
                          for (i = 0; i < geoms.length; ++i) {
                              geoms[i].setAttribute('visibility', 'hidden');
                          }
                          entry.setAttribute('opacity', 0.5);
                      } else {
                          for (i = 0; i < geoms.length; ++i) {
                              geoms[i].setAttribute('visibility', 'visible');
                          }
                          entry.setAttribute('opacity', 1.0);
                      }", label, label))
        swatch <<= svglink("#")
        swatch_canvas <<= swatch
    end
    swatch_canvas <<= font(theme.minor_label_font) |
                      fontsize(theme.minor_label_font_size)

    c = canvas(0, 0, max(title_width, entry_width) + 3swatch_padding,
               swatch_canvas.box.height + title_canvas.box.height) <<
        pad(canvas() << swatch_canvas << title_canvas, 2mm)

    {(c, right_guide_position)}
end



type XTicks <: Gadfly.GuideElement
end

const x_ticks = XTicks()


function render(guide::XTicks, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    ticks = Dict{Float64, String}()
    for aes in aess
        if Gadfly.issomething(aes.xtick)
            for val in aes.xtick
                ticks[val] = aes.xtick_label(val)
            end
        end
    end

    # grid lines
    grid_lines = compose(canvas(),
                         [lines((t, 0h), (t, 1h)) for (t, _) in ticks]...,
                         stroke(theme.grid_color),
                         linewidth(theme.grid_line_width))

    # tick labels
    (_, height) = text_extents(theme.minor_label_font,
                               theme.minor_label_font_size,
                               values(ticks)...)
    #padding = 1mm
    padding = 0mm

    tick_labels = compose(canvas(0, 0, 1w, height + 2padding),
                          [text(tick, 1h - padding, label, hcenter, vbottom)
                           for (tick, label) in ticks]...,
                          stroke(nothing),
                          fill(theme.minor_label_color),
                          font(theme.minor_label_font),
                          fontsize(theme.minor_label_font_size))

    {(grid_lines, under_guide_position),
     (tick_labels, bottom_guide_position)}
end


type YTicks <: Gadfly.GuideElement
end

const y_ticks = YTicks()

function render(guide::YTicks, theme::Gadfly.Theme,
                aess::Vector{Gadfly.Aesthetics})
    ticks = Dict{Float64, String}()
    for aes in aess
        if Gadfly.issomething(aes.ytick)
            for val in aes.ytick
                ticks[val] = aes.ytick_label(val)
            end
        end
    end

    # grid lines
    grid_lines = compose(canvas(),
                         [lines((0w, t), (1w, t)) for (t, _) in ticks]...,
                         stroke(theme.grid_color),
                         linewidth(theme.grid_line_width))

    # tick labels
    (width, _) = text_extents(theme.minor_label_font,
                              theme.minor_label_font_size,
                              values(ticks)...)
    padding = 1mm
    width += 2padding

    tick_labels = compose(canvas(0, 0, width, 1cy),
                          [text(width - padding, t, label, hright, vcenter)
                           for (t, label) in ticks]...,
                          stroke(nothing),
                          fill(theme.minor_label_color),
                          font(theme.minor_label_font),
                          fontsize(theme.minor_label_font_size))

    {(grid_lines, under_guide_position),
     (tick_labels, left_guide_position)}
end


# X-axis label Guide
type XLabel <: Gadfly.GuideElement
    label::String
end


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
type YLabel <: Gadfly.GuideElement
    label::String
end


function render(guide::YLabel, theme::Gadfly.Theme, aess::Vector{Gadfly.Aesthetics})
    (text_width, text_height) = text_extents(theme.major_label_font,
                                             theme.major_label_font_size,
                                             guide.label)
    padding = 2mm
    c = compose(canvas(0, 0, text_height + 2padding, 1cy,
                       Rotation(-0.5pi, 0.5w, 0.5h)),
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
                       guides::(Canvas, GuidePosition)...)

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

    reverse!(left_guides)

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
    right_guides  = set_box(right_guides,  BoundingBox(l + pw, t, r, ph))
    bottom_guides = set_box(bottom_guides, BoundingBox(l, t + ph, pw, b))
    left_guides   = set_box(left_guides,   BoundingBox(0, t, l, ph))

    compose(canvas(),
            (canvas(l, t, pw, ph), under_guides, plot_canvas),
            top_guides, right_guides, bottom_guides, left_guides)
end

end # module Guide

