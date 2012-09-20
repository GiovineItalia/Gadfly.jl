
insert(LOAD_PATH, 1, real_path("../compose/"))
require("compose.jl")

require("theme.jl")
require("aesthetics.jl")


abstract Guide
typealias Guides Vector{Guide}


type PanelBackground <: Guide
end

const guide_background = PanelBackground()


function render(guide::PanelBackground, theme::Theme, aess::Vector{Aesthetics})
    [compose!(Canvas(), Rectangle(),
              Stroke(nothing),
              Fill(theme.panel_background))]
end


type XTicks <: Guide
end

const guide_x_ticks = XTicks()


function render(guide::XTicks, theme::Theme, aess::Vector{Aesthetics})
    println("render xticks")

    ticks = Dict{Float64, String}()
    for aes in aess
        if issomething(aes.xtick) && issomething(aes.xtick_labels)
            for (val, label) in zip(aes.xtick, aes.xtick_labels)
                ticks[val] = label
            end
        end
    end

    form = Form()
    for (tick, label) in ticks
        compose!(form, Lines((tick, 0h), (tick, 1h)))
    end
    grid_lines = compose!(Canvas(), form, Stroke(theme.grid_color))

    (_, height) = text_extents(theme.tick_label_font,
                               theme.tick_label_font_size,
                               values(ticks)...)
    padding = 1mm

    tick_labels = compose!(Canvas(0cx, 1cy, 1w, height + 2padding),
                           Stroke(nothing), Fill(theme.tick_label_color),
                           Font(theme.tick_label_font),
                           FontSize(theme.tick_label_font_size))
    for (tick, label) in ticks
        compose!(tick_labels, Text(tick, 1h - padding,
                                   label, hcenter, vbottom))
    end

    [grid_lines, tick_labels]
end


type YTicks <: Guide
end

const guide_y_ticks = YTicks()

function render(guide::YTicks, theme::Theme, aess::Vector{Aesthetics})
    println("render yticks")

    ticks = Dict{Float64, String}()
    for aes in aess
        if issomething(aes.ytick) && issomething(aes.ytick_labels)
            for (val, label) in zip(aes.ytick, aes.ytick_labels)
                ticks[val] = label
            end
        end
    end

    println(ticks)

    form = Form()
    for (tick, label) in ticks
        compose!(form, Lines((0w, tick), (1w, tick)))
    end
    grid_lines = compose!(Canvas(), form, Stroke(theme.grid_color))

    (width, _) = text_extents(theme.tick_label_font,
                              theme.tick_label_font_size,
                              values(ticks)...)
    padding = 1mm
    width += 2padding

    tick_labels = compose!(Canvas(0cx, 0cy, width, 1cy),
                           Stroke(nothing), Fill(theme.tick_label_color),
                           Font(theme.tick_label_font),
                           FontSize(theme.tick_label_font_size))
    for (tick, label) in ticks
        compose!(tick_labels, Text(width - padding, tick,
                                   label, hright, vcenter))
    end

    [grid_lines, tick_labels]
end


# Try to arrange a bunch of rendered guides (as canvases) using some
# simple rules:
#   1. If the canvas has width 1w and height 1h (i.e., parents coordinates)
#      embed it in the plot's canvas.
#   2. Otherwise, we expect a side to be given by the canvases position to be
#
# TODO: This is an ugly hack and points to shortcommings in compose. Think of
# how a more general layout mechanism can be added to compose.

function layout_guides(plot_canvas::Canvas, guide_canvases::Canvas...)

    # Make one pass to build up all the guides that are plotted over the
    # the panel before composing with the plot canvas.
    root_canvas = Canvas(0cx, 0cy, 1cx, 1cy,
                         Units(plot_canvas.unit_box))
    isfull = c -> c.box.width == 1w && c.box.height == 1h
    for c in filter(isfull, guide_canvases)
        c.unit_box = plot_canvas.unit_box
        compose!(root_canvas, c)
    end
    compose!(root_canvas, plot_canvas)
    plot_canvas = root_canvas

    for c in filter(negate(isfull), guide_canvases)
        c.unit_box = plot_canvas.unit_box

        # left-aligned
        if c.box.x0 == 0cx && c.box.height == 1cy
            root_canvas.box.x0    = c.box.width
            root_canvas.box.width -= c.box.width
            c.box.height = plot_canvas.box.height
        # bottom
        elseif c.box.y0 == 1cy && c.box.width == 1w
            root_canvas.box.height -= c.box.height
            c.box.y0 -= c.box.height
        end
        # TODO: others

        root_canvas = compose(Canvas(0cx, 0cy, 1cx, 1cy), root_canvas, c)
    end

    root_canvas
end

