
insert(LOAD_PATH, 1, real_path("../compose/"))
require("compose.jl")

require("theme.jl")
require("aesthetics.jl")


abstract Guide
typealias Guides Vector{Guide}


type PanelBackground <: Guide
end

const panel_background = PanelBackground()


function render(guide::PanelBackground, theme::Theme, aess::Vector{Aesthetics})
    compose!(Rectangle(), Stroke(nothing), Fill(theme.panel_background))
end


# How can we accomplish ggplot's trick fo drawing the numbers on a log10 scale
# with exponents? We would need knowledge of the scale.  Maybe, or we could have
# tho scale implemente a backwards map as well. That could be pretty akward.

# Maybe scale should compute ticks and labels.

# What was the original objetion to that idea?

# The alternative is to expose the actual scales and have some sort of backwards
# map. Or a funtion to label points. That's not a terrible idea: we might want
# such a thing in other places. For example, if we want to implement tooltips
# that label points on hover, we need just such a thing.

# Ok, so how can we implement this:
# The ploblem is that we allow multiple scales, so which inverse map function
# gets called exactly?

# We need to call each in sequence. If scales are applied like:
#   f(g(x)), we need to call g'(f'(x)). Do these functions live the Aessthetics?
# I'm tempted to say yes, because that would allow the user te define their own
# label function.

# Ok, how about this:
# What if a custom transformation is used that can not be inverted.
# Or, simpler than that. What if the inverse isn't known by the plot.
# We could insist an inverse is supplied.

# Too complicated. Let's just have scales compute xticks, yticks, etc.
# Then later on we can add other tick aesthetics.




type XTicks <: Guide
end

const x_ticks = XTicks()

function render(guide::XTicks, theme::Theme, aess::Vector{Aesthetics})
    println("render xticks")
    ticks = Dict{Float64, String}()
    for aes in aess
        if issomething(aes.xticks)
            merge!(ticks, aes.xticks)
        end
    end

    form = Form()
    for (tick, label) in ticks
        compose!(form, Lines((tick, 0h), (tick, 1h)))
    end
    compose!(form, Stroke(theme.grid_color))
end



type YTicks <: Guide
end

const y_ticks = YTicks()

function render(guide::YTicks, theme::Theme, aess::Vector{Aesthetics})
    println("render yticks")
    ticks = Dict{Float64, String}()
    for aes in aess
        if issomething(aes.yticks)
            merge!(ticks, aes.yticks)
        end
    end

    form = Form()
    for (tick, label) in ticks
        compose!(form, Lines((0w, tick), (1w, tick)))
    end
    compose!(form, Stroke(theme.grid_color))
end
