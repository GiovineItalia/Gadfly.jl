

# Bar geometry summarizes data as vertical bars.
immutable BarGeometry <: Gadfly.GeometryElement
    # How bars should be positioned if they are grouped by color.
    # Valid options are:
    #   :stack -> place bars on top of each other (default)
    #   :dodge -> place bar next to each other
    position::Symbol

    function BarGeometry(position=:stack)
        new(position)
    end
end


const bar = BarGeometry
const histogram = BarGeometry


function element_aesthetics(::BarGeometry)
    [:x, :y, :color]
end


function default_statistic(::BarGeometry)
    Gadfly.Stat.histogram()
end


# Render a single color bar chart
function render_colorless_bar(geom::BarGeometry,
                              theme::Gadfly.Theme,
                              aes::Gadfly.Aesthetics)
    bar_form = empty_form
    for (x_min, x_max, y) in zip(aes.x_min, aes.x_max, aes.y)
        geometry_id = Gadfly.unique_svg_id()
        bar_form |= compose(rectangle(x_min*cx + theme.bar_spacing/2, 0.0,
                                      (x_max - x_min)*cx - theme.bar_spacing, y),
                            svgid(geometry_id), svgclass("geometry"))
    end
    bar_form
end


# Render a bar chart grouped by discrete colors and stacked.
function render_colorful_stacked_bar(geom::BarGeometry,
                                     theme::Gadfly.Theme,
                                     aes::Gadfly.Aesthetics)
    bar_form = empty_form

    stack_height = Dict()
    for x_min in aes.x_min
        stack_height[x_min] = 0.0
    end

    for i in sortperm(aes.color.refs, rev=true)
        x_min, x_max, y, c = aes.x_min[i], aes.x_max[i], aes.y[i], aes.color[i]
        geometry_id = Gadfly.unique_svg_id()
        bar_form |= compose(rectangle(x_min*cx + theme.bar_spacing/2,
                                      stack_height[x_min],
                                      (x_max - x_min)*cx - theme.bar_spacing,
                                      y),
                            fill(c),
                            svgid(geometry_id),
                            svgclass("geometry"))
        stack_height[x_min] += y
    end
    bar_form
end


# Render a bar chart grouped by discrete colors and stuck next to each other.
function render_colorful_dodged_bar(geom::BarGeometry,
                                    theme::Gadfly.Theme,
                                    aes::Gadfly.Aesthetics)
    bar_form = empty_form
    dodge_width = Dict()
    dodge_count = Dict()
    for x_min in aes.x_min
        dodge_width[x_min] = 0.0cx
        dodge_count[x_min] = get(dodge_count, x_min, 0) + 1
    end

    for i in sortperm(aes.color.refs, rev=true)
        x_min, x_max, y, c = aes.x_min[i], aes.x_max[i], aes.y[i], aes.color[i]
        geometry_id = Gadfly.unique_svg_id()
        barwidth = ((x_max - x_min)*cx - theme.bar_spacing) / dodge_count[x_min]
        bar_form |= compose(rectangle(x_min*cx + dodge_width[x_min] + theme.bar_spacing/2,
                                      0.0,
                                      barwidth,
                                      y),
                            fill(c),
                            svgid(geometry_id),
                            svgclass("geometry"))
        dodge_width[x_min] += barwidth
    end
    bar_form
end


# Render bar geometry.
#
# Args:
#   geom: bar geometry
#   theme: the plot's theme
#   aes: some aesthetics
#
# Returns
#   A compose form.
#
function render(geom::BarGeometry, theme::Gadfly.Theme, aes::Gadfly.Aesthetics)
    Gadfly.assert_aesthetics_defined("Geom.bar", aes, :y)
    if (is(aes.x_min, nothing) || is(aes.x_max, nothing)) && is(aes.x, nothing)
        error("Geom.bar required \"x\" to be bound or both \"x_min\" and \"x_max\".")
    end

    if aes.x_min === nothing
        aes2 = Gadfly.Aesthetics()
        aes2.x_min = Array(Float64, length(aes.x))
        aes2.x_max = Array(Float64, length(aes.x))
        for (i, x) in enumerate(aes.x)
            aes2.x_min[i] = x - 0.5
            aes2.x_max[i] = x + 0.5
        end
        aes = inherit(aes, aes2)
    end

    if aes.color === nothing
        form = render_colorless_bar(geom, theme, aes)
    elseif geom.position == :stack
        form = render_colorful_stacked_bar(geom, theme, aes)
    elseif geom.position == :dodge
        form = render_colorful_dodged_bar(geom, theme, aes)
    else
        error("$(geom.position) is not a valid position for the bar geometry.")
    end

    compose(canvas(units_inherited=true),
            form,
            svgattribute("shape-rendering", "crispEdges"),
            fill(theme.default_color),
            stroke(nothing))
end


