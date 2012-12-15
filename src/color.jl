
# Various color scales.

using Compose

# Discrete scales
# Each of these functions produce a vector of n colors.

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
    [LCHab(l, c, h0 + 360.0 * (i - 1) / n) for i in 1:n]
end

function luv_rainbow(l, c, h0, n)
    [LCHuv(l, c, h0 + 360.0 * (i - 1) / n) for i in 1:n]
end

# Helpful for Experimenting
function plot_color_scale{T <: Color}(colors::Vector{T})
    println(colors)
    canvas(Units(length(colors), 1)) <<
            (compose([rectangle(i-1, 0, 1, 1) << fill(c)
                      for (i, c) in enumerate(colors)]...) << stroke(nothing))
end



