
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
    p = stroke(nothing) | fill(theme.panel_background)
    Canvas[canvas() << (rectangle() << p)]
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

    form = compose([lines((tick, 0h), (tick, 1h)) for (tick, label) in ticks]...)
    grid_lines = canvas() << (form << stroke(theme.grid_color))

    (_, height) = text_extents(theme.tick_label_font,
                               theme.tick_label_font_size,
                               values(ticks)...)
    padding = 1mm


    tick_labels = compose([text(tick, 1h - padding, label, hcenter, vbottom)
                           for (tick, label) in ticks]...)
    tick_labels <<= stroke(nothing) |
                    fill(theme.tick_label_color) |
                    font(theme.tick_label_font) |
                    fontsize(theme.tick_label_font_size)
    tick_labels = canvas(0cx, 1cy, 1w, height + 2padding) << tick_labels

    Canvas[grid_lines, tick_labels]
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

    form = compose([lines((0w, tick), (1w, tick)) for (tick, label) in ticks]...)
    grid_lines = canvas() << (form << stroke(theme.grid_color))

    (width, _) = text_extents(theme.tick_label_font,
                              theme.tick_label_font_size,
                              values(ticks)...)
    padding = 1mm
    width += 2padding


    tick_labels = compose([text(width - padding, tick, label, hright, vcenter)
                           for (tick, label) in ticks]...)
    tick_labels <<= stroke(nothing) |
                    fill(theme.tick_label_color) |
                    font(theme.tick_label_font) |
                    fontsize(theme.tick_label_font_size)
    tick_labels = canvas(0cx, 0cy, width, 1cy) << tick_labels

    Canvas[grid_lines, tick_labels]
end


# Try to arrange a bunch of rendered guides (as canvases) using some
# simple rules:
#   1. If the canvas has width 1w and height 1h (i.e., parents coordinates)
#      embed it in the plot's canvas.
#   2. Otherwise, we expect a side to be given by the canvases position to be
#
# TODO: This is an ugly hack and points to shortcommings in compose. Think of
# how a more general layout mechanism can be added to compose.

# Let's think through how this could be done more elegently, or at least in a
# way that doesn't make me cringe.


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

