

# Bar geometry summarizes data as vertical bars.
immutable BarGeometry <: Gadfly.GeometryElement
    # How bars should be positioned if they are grouped by color.
    # Valid options are:
    #   :stack -> place bars on top of each other (default)
    #   :dodge -> place bar next to each other
    position::Symbol

    default_statistic::Gadfly.StatisticElement

    function BarGeometry(position=:stack,
                         default_statistic=Gadfly.Stat.identity())
        new(position, default_statistic)
    end
end


const bar = BarGeometry

function histogram(position=:stack)
    BarGeometry(position, Gadfly.Stat.histogram())
end


function element_aesthetics(::BarGeometry)
    [:x, :y, :color]
end


function default_statistic(geom::BarGeometry)
    geom.default_statistic
end


# Render a single color bar chart
function render_colorless_bar(geom::BarGeometry,
                              theme::Gadfly.Theme,
                              aes::Gadfly.Aesthetics)
    bar_form = empty_form
    for (x_min, x_max, y) in zip(aes.xmin, aes.xmax, aes.y)
        geometry_id = Gadfly.unique_svg_id()
        bar_form = combine(bar_form,
            compose(rectangle(x_min*cx + theme.bar_spacing/2, 0.0,
                              (x_max - x_min)*cx - theme.bar_spacing, y),
                    svgid(geometry_id), svgclass("geometry")))
    end
    bar_form
end


# Render a bar chart grouped by discrete colors and stacked.
function render_colorful_stacked_bar(geom::BarGeometry,
                                     theme::Gadfly.Theme,
                                     aes::Gadfly.Aesthetics)
    bar_form = empty_form

    stack_height = Dict()
    for x_min in aes.xmin
        stack_height[x_min] = 0.0
    end

    for i in sortperm(aes.color.refs, rev=true)
        x_min, x_max, y, c = aes.xmin[i], aes.xmax[i], aes.y[i], aes.color[i]
        geometry_id = Gadfly.unique_svg_id()
        bar_form = combine(bar_form,
            compose(rectangle(x_min*cx + theme.bar_spacing/2,
                              stack_height[x_min],
                              (x_max - x_min)*cx - theme.bar_spacing, y),
                    fill(c),
                    svgid(geometry_id),
                    svgclass("geometry")))
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
    for x_min in aes.xmin
        dodge_width[x_min] = 0.0cx
        dodge_count[x_min] = get(dodge_count, x_min, 0) + 1
    end

    for i in sortperm(aes.color.refs, rev=true)
        x_min, x_max, y, c = aes.xmin[i], aes.xmax[i], aes.y[i], aes.color[i]
        geometry_id = Gadfly.unique_svg_id()
        barwidth = ((x_max - x_min)*cx - theme.bar_spacing) / dodge_count[x_min]
        bar_form = combine(bar_form,
            compose(rectangle(x_min*cx + dodge_width[x_min] + theme.bar_spacing/2,
                              0.0, barwidth, y),
                    fill(c),
                    svgid(geometry_id),
                    svgclass("geometry")))
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
    if (is(aes.xmin, nothing) || is(aes.xmax, nothing)) && is(aes.x, nothing)
        error("Geom.bar required \"x\" to be bound or both \"x_min\" and \"x_max\".")
    end

    if aes.xmin === nothing
        aes2 = Gadfly.Aesthetics()
        T = eltype(aes.x)
        aes2.xmin = Array(T, length(aes.x))
        aes2.xmax = Array(T, length(aes.x))

        span = zero(T)
        if !isempty(aes.x)
            span = (maximum(aes.x) - minimum(aes.x)) / (length(Set(aes.x...)) - 1)
        end

        if span == zero(T)
            span = one(T)
        end

        for (i, x) in enumerate(aes.x)
            aes2.xmin[i] = x - span/2
            aes2.xmax[i] = x + span/2
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


