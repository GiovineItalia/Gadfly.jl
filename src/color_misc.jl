# Various color scales.

"""
    function weighted_color_mean(cs::AbstractArray{Lab{T},1},
                                 ws::AbstractArray{S,1}) where {S <: Number,T}
Return the mean of Lab colors `cs` as weighted by `ws`.
"""
function weighted_color_mean(
        cs::AbstractArray{Lab{T},1}, ws::AbstractArray{S,1}) where {S <: Number,T}
    l = 0.0
    a = 0.0
    b = 0.0
    sumws = sum(ws)
    for (c, w) in zip(cs, ws)
        w /= sumws
        l += w * c.l
        a += w * c.a
        b += w * c.b
    end
    Lab(l, a, b)
end


# Discrete scales

"""
    lab_rainbow(l, c, h0, n)

Generate `n` colors in the LCHab colorspace by using a fixed
luminance `l` and chroma `c`, and varying the hue, starting at `h0`.
"""
lab_rainbow(l, c, h0, n) = [LCHab(l, c, h0 + 360.0 * (i - 1) / n) for i in 1:n]

"""
    luv_rainbow(l, c, h0, n)

Generate `n` colors in the LCHuv colorspace by using a fixed
luminance `l` and chroma `c`, and varying the hue, starting at `h0`.
"""
luv_rainbow(l, c, h0, n) = [LCHuv(l, c, h0 + 360.0 * (i - 1) / n) for i in 1:n]

# Helpful for Experimenting
function plot_color_scale(colors::Vector{T}) where T <: Color
    println(colors)
    canvas(UnitBox(length(colors), 1)) <<
            (compose([rectangle(i-1, 0, 1, 1) << fill(c)
                      for (i, c) in enumerate(colors)]...) << stroke(nothing))
end


# Continuous scales


"""
    function lab_gradient(cs::Color...)

Generate a function `f(p)` that creates a gradient between n≥2 colors, where `0≤p≤1`.
If you have a collection of colors, then use the splatting operator `...`:
```julia
f = Scale.lab_gradient(range(HSV(0,1,1), stop=HSV(250,1,1), length=100)...)
```
Function `f` can be used like so: `Scale.color_continuous(colormap=f)`.
"""
function lab_gradient(cs::Color...)
    length(cs) < 2 && error("Two or more colors are needed for gradients")

    cs_lab = [convert(Lab, c) for c in cs]
    n = length(cs_lab)
    function f(p::Float64)
        @assert 0.0 <= p <= 1.0
        i = 1 + min(n - 2, max(0, floor(Int, p*(n-1))))
        w = p*(n-1) + 1 - i
        weighted_color_mean([cs_lab[i], cs_lab[i+1]], [1.0 - w, w])
    end
    f
end

"""
    function lab_gradient(cs...)

Can be applied to other types, e.g. `Scale.lab_gradient("blue","ghostwhite","red")`
"""
lab_gradient(cs...) = lab_gradient(Gadfly.parse_colorant(cs)...)

"""
    function lchabmix(c0_, c1_, r, power)
"""
function lchabmix(c0_, c1_, r, power)
    c0 = convert(LCHab, c0_)
    c1 = convert(LCHab, c1_)
    w = r^power
    lspan = c1.l - c0.l
    cspan = c1.c - c0.c
    hspan = c1.h - c0.h
    return LCHab(c0.l + w*lspan, c0.c + w*cspan, c0.h + w*hspan)
end
