
# Various color scales.

# Discrete scales
# ---------------

# Generate colors in the LCHab (LCHuv, resp.) colorspace by using a fixed
# luminance and chroma, and varying the hue.
#
# Args:
#   l: luminance
#   c: chroma
#   h0: start hue
#   n: number of colors
#
function lab_rainbow(l, c, h0, n)
    Color[LCHab(l, c, h0 + 360.0 * (i - 1) / n) for i in 1:n]
end

function luv_rainbow(l, c, h0, n)
    Color[LCHuv(l, c, h0 + 360.0 * (i - 1) / n) for i in 1:n]
end

# Helpful for Experimenting
function plot_color_scale{T <: Color}(colors::Vector{T})
    println(colors)
    canvas(Units(length(colors), 1)) <<
            (compose([rectangle(i-1, 0, 1, 1) << fill(c)
                      for (i, c) in enumerate(colors)]...) << stroke(nothing))
end


# Continuous scales
# -----------------

# Generate a gradient between n >= 2, colors.

# Then functions return functions suitable for ContinuousColorScales.
function lab_gradient(cs::Color...)
    if length(cs) < 2
        error("Two or more colors are needed for gradients")
    end

    cs_lab = [convert(LAB, c) for c in cs]
    n = length(cs_lab)
    function f(p::Float64)
        @assert 0.0 <= p <= 1.0
        i = 1 + min(n - 2, max(0, int(floor(p*(n-1)))))
        w = p*(n-1) + 1 - i
        weighted_color_mean([cs_lab[i], cs_lab[i+1]], [1.0 - w, w])
    end
    f
end

