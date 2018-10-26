# Compose pseudo-forms for simple symbols, all parameterized by center and size

module Shape

using Measures
using Compose: x_measure, y_measure, circle, rectangle, polygon, line, px

shape_docstr(kinds) = "Draw $kinds at the coordinates specified in `xs` and
`ys` of size `rs`"

"""
    square(xs, ys, rs)

$(shape_docstr("squares"))
"""
function square(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
    n = max(length(xs), length(ys), length(rs))

    s = 1/sqrt(2)
    polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, n)

    for i in 1:n
        x = x_measure(xs[mod1(i, length(xs))])
        y = y_measure(ys[mod1(i, length(ys))])
        r = rs[mod1(i, length(rs))]
        polys[i] = Tuple{Measure,Measure}[(x-s*r,y-s*r),(x-s*r,y+s*r),(x+s*r,y+s*r),(x+s*r,y-s*r)] 
    end

    return polygon(polys)
end

"""
    diamond(xs, ys, rs)

$(shape_docstr("diamonds"))
"""
function diamond(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
    n = max(length(xs), length(ys), length(rs))

    polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, n)
    for i in 1:n
        x = x_measure(xs[1 + i % length(xs)])
        y = y_measure(ys[1 + i % length(ys)])
        r = rs[1 + i % length(rs)]
        polys[i] = Tuple{Measure, Measure}[(x, y - r), (x + r, y), (x, y + r), (x - r, y)]
    end

    return polygon(polys)
end

"""
    cross(xs, ys, rs)

$(shape_docstr("crosses"))
"""
function cross(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
  n = max(length(xs), length(ys), length(rs))
  polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, n)
  for i in 1:n
    x = x_measure(xs[mod1(i, length(xs))])
    y = y_measure(ys[mod1(i, length(ys))])
    r = rs[mod1(i, length(rs))]
    u = 0.4r

    # make a "plus sign"
    polys[i] = Tuple{Measure, Measure}[
      (x-r, y-u), (x-r, y+u), # L edge
      (x-u, y+u),             # BL inside
      (x-u, y+r), (x+u, y+r), # B edge
      (x+u, y+u),             # BR inside
      (x+r, y+u), (x+r, y-u), # R edge
      (x+u, y-u),             # TR inside
      (x+u, y-r), (x-u, y-r), # T edge
      (x-u, y-u)              # TL inside
    ]
  end

  return polygon(polys)
end

"""
    xcross(xs, ys, rs)

$(shape_docstr("rotated crosses"))
"""
function xcross(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
  n = max(length(xs), length(ys), length(rs))
  polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, n)
  s = 1/sqrt(5)
  for i in 1:n
    x = x_measure(xs[mod1(i, length(xs))])
    y = y_measure(ys[mod1(i, length(ys))])
    r = rs[mod1(i, length(rs))]
    u = s*r
    polys[i] = Tuple{Measure, Measure}[
      (x, y - u), (x + u, y - 2u), (x + 2u, y - u),
      (x + u, y), (x + 2u, y + u), (x + u, y + 2u),
      (x, y + u), (x - u, y + 2u), (x - 2u, y + u),
      (x - u, y), (x - 2u, y - u), (x - u, y - 2u)
    ]
  end

  return polygon(polys)
end

"""
    utriangle(xs, ys, rs, scalar=1)

$(shape_docstr("upward-pointing triangles"))
"""
function utriangle(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray, scalar = 1)
  n = max(length(xs), length(ys), length(rs))
  polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, n)
  
  for i in 1:n
    x = x_measure(xs[mod1(i, length(xs))])
    y = y_measure(ys[mod1(i, length(ys))])
    r = rs[mod1(i, length(rs))]
    u = 0.87 * r
    v = scalar * r    
    polys[i] = Tuple{Measure, Measure}[
      (x - u, y + 0.5v),
      (x + u, y + 0.5v),
      (x, y - v),  # two of these so the centroid is such that it zooms well
      (x, y - v)
    ]
  end

  return polygon(polys)
end

"""
    dtriangle(xs, ys, rs)

$(shape_docstr("downward-pointing triangles"))
"""
dtriangle(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray) = utriangle(xs, ys, rs, -1)

"""
    star1(xs, ys, rs, scalar=1)

$(shape_docstr("five-pointed stars"))
"""
function star1(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray, scalar = 1)
  n = max(length(xs), length(ys), length(rs))
  polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, n)
  
  # some magic scalars
  sx = 0.7
  sy1, sy2 = 1.2, 0.4

  for i in 1:n
    x = x_measure(xs[mod1(i, length(xs))])
    y = y_measure(ys[mod1(i, length(ys))])
    r = rs[mod1(i, length(rs))]
    polys[i] = Tuple{Measure, Measure}[
      (x-sx*r, y+r),      # BL
      (x,      y-sy1*r),  # T
      (x+sx*r, y+r),      # BR
      (x-r,    y-sy2*r),  # L
      (x+r,    y-sy2*r)   # R
    ]
  end

  return polygon(polys)
end

"""
    star2(xs, ys, rs, scalar=1)

$(shape_docstr("four-pointed stars"))
"""
function star2(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray, scalar = 1)
  n = max(length(xs), length(ys), length(rs))
  polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, n)
  for i in 1:n
    x = x_measure(xs[mod1(i, length(xs))])
    y = y_measure(ys[mod1(i, length(ys))])
    r = rs[mod1(i, length(rs))]
    u = 0.4r
    polys[i] = Tuple{Measure, Measure}[
      (x-u, y),   (x-r, y-r), # TL
      (x,   y-u), (x+r, y-r), # TR
      (x+u, y),   (x+r, y+r), # BR
      (x,   y+u), (x-r, y+r)  # BL
    ]
  end

  return polygon(polys)
end

"""
    hexagon(xs, ys, rs)

$(shape_docstr("hexagons"))
"""
function hexagon(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
  n = max(length(xs), length(ys), length(rs))

  polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, n)
  for i in 1:n
    x = x_measure(xs[mod1(i, length(xs))])
    y = y_measure(ys[mod1(i, length(ys))])
    r = rs[mod1(i, length(rs))]
    v = 0.5r
    u = 0.87r    
    polys[i] = Tuple{Measure, Measure}[
      (x-u, y-v), (x-u, y+v), # L edge
      (x, y+r),               # B
      (x+u, y+v), (x+u, y-v), # R edge
      (x, y-r)                # T
    ]
  end

  return polygon(polys)
end

"""
    octagon(xs, ys, rs)

$(shape_docstr("octagons"))
"""
function octagon(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
  n = max(length(xs), length(ys), length(rs))

  polys = Vector{Vector{Tuple{Measure, Measure}}}(undef, n)
  for i in 1:n
    x = x_measure(xs[mod1(i, length(xs))])
    y = y_measure(ys[mod1(i, length(ys))])
    r = rs[mod1(i, length(rs))]
    u = 0.4r

    polys[i] = Tuple{Measure, Measure}[
      (x-r, y-u), (x-r, y+u), # L edge
      (x-u, y+r), (x+u, y+r), # B edge
      (x+r, y+u), (x+r, y-u), # R edge
      (x+u, y-r), (x-u, y-r)  # T edge
    ]
  end

  return polygon(polys)
end

"""
    hline(xs, ys, rs)

$(shape_docstr("horizontal lines"))
"""
function hline(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
    n = max(length(xs), length(ys), length(rs))

    line_ps = Vector{Vector{Tuple{Measure,Measure}}}(undef, n)
    for i in 1:n
        x = x_measure(xs[1 + i % length(xs)])
        y = y_measure(ys[1 + i % length(ys)])
        r = rs[1 + i % length(rs)]
        line_ps[i] = Tuple{Measure, Measure}[(x-r,y-1.5px),(x+r,y-1.5px),(x+r,y+1.5px),(x-r,y+1.5px)]
    end

    return polygon(line_ps)
end

"""
    vline(xs, ys, rs)

$(shape_docstr("vertical lines"))
"""
function vline(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
    n = max(length(xs), length(ys), length(rs))

    line_ps = Vector{Vector{Tuple{Measure,Measure}}}(undef, n)
    for i in 1:n
        x = x_measure(xs[1 + i % length(xs)])
        y = y_measure(ys[1 + i % length(ys)])
        r = rs[1 + i % length(rs)]
        line_ps[i] = Tuple{Measure, Measure}[(x-1.5px,y-r),(x-1.5px,y+r),(x+1.5px,y+r),(x+1.5px,y-r)]
    end

    return polygon(line_ps)
end

end  # module Shape
