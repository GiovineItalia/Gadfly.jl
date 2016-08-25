

# Particularly useful or beautiful grammar of graphics invocations.


# A convenience plot function for quickly plotting functions or expressions.
#
# Args:
#   fs: An array in which each object is either a single argument function or an
#       expression computing some value on x.
#   a: Lower bound on x.
#   b: Upper bound on x.
#   elements: One ore more grammar elements.
#
# Returns:
#   A plot objects.
#
function plot{T <: Base.Callable}(fs::Vector{T}, a::Number, b::Number, elements::ElementOrFunction...; mapping...)
    if isempty(elements)
        elements = ElementOrFunction[]
    elseif isa(elements, Tuple)
        elements = ElementOrFunction[elements...]
    end

    element_types = Set(map(typeof, elements))

    if !in(Guide.xlabel, element_types)
        push!(elements, Guide.xlabel("x"))
    end

    if !in(Guide.ylabel, element_types)
        push!(elements, Guide.ylabel("f(x)"))
    end

    if b < a
        push!(elements, Coord.cartesian(xflip=true))
    end

    mappingdict = @compat Dict{Symbol, Any}(:y => fs, :xmin => [a], :xmax => [b])
    for (k, v) in mapping
        mappingdict[k] = v
    end

    plot(Stat.func, Geom.line, elements...; mappingdict...)
end


# Plot a single function.
function plot(f::Function, a::Number, b::Number, elements::ElementOrFunction...; mapping...)
    plot(Function[f], a, b, elements...; mapping...)
end


# Plot a single function using a contour plot
function plot(f::Function, xmin::Number, xmax::Number, ymin::Number, ymax::Number,
              elements::ElementOrFunction...; mapping...)
    default_elements = ElementOrFunction[]
    element_types = Set(map(typeof, elements))

    if !in(Guide.xlabel, element_types)
        push!(default_elements, Guide.xlabel("x"))
    end

    if !in(Guide.ylabel, element_types)
        push!(default_elements, Guide.ylabel("y"))
    end

    if !in(Guide.ColorKey, element_types) && !in(Guide.ManualColorKey, element_types)
        push!(default_elements, Guide.colorkey("f(x,y)"))
    end

    push!(default_elements, Coord.cartesian(xflip=xmin > xmax, yflip=ymin > ymax))

    plot(layer(f, xmin, xmax, ymin, ymax,
               elements...; mapping...), default_elements...)
end


function layer(f::Function, xmin::Number, xmax::Number, ymin::Number, ymax::Number,
               elements::ElementOrFunction...; mapping...)
    if isempty(elements)
        elements = ElementOrFunction[]
    elseif isa(elements, Tuple)
        elements = ElementOrFunction[elements...]
    end


    mappingdict = @compat Dict{Symbol, Any}(:z    => f, :xmin => [xmin], :xmax => [xmax],
                                            :ymin => [ymin], :ymax => [ymax])
    for (k, v) in mapping
        mappingdict[k] = v
    end

    layer(Geom.contour, elements...; mappingdict...)
end



# Create a layer from a list of functions or expressions.
function layer(fs::Array, a::Number, b::Number, elements::ElementOrFunction...)
    layer(y=fs, xmin=[a], xmax=[b], Stat.func, Geom.line, elements...)
end


# Create a layer from a single function.
function layer(f::Function, a::Number, b::Number, elements::ElementOrFunction...)
    layer([f], a, b, elements...)
end


# Simple heatmap plots of matrices.
#
# It is a wrapper around the `plot()` function using the `rectbin` geometry.
# It also applies a sane set of defaults to make sure that the plots look nice
# by default. Specifically
#   - the aspect ratio of the coordinate system is fixed Coord.cartesian(fixed=true),
#     so that the rectangles become squares
#   - the axes run from 0.5 to N+0.5, because the first row/column is drawn to
#     (0.5, 1.5) and the last one to (N-0.5, N+0.5).
#   - the y-direction is flipped, so that the [1,1] of a matrix is in the top
#     left corner, as is customary
#   - NaNs are not drawn. `spy` leaves "holes" instead into the heatmap.
#
# Args:
#   M: A matrix.
#
# Returns:
#   A plot object.
#
# Known bugs:
#   - If the matrix is only NaNs, then it throws an `ArgumentError`, because
#     an empty collection gets passed to the `plot` function / `rectbin` geometry.
#
"""
```
spy(M::AbstractMatrix, elements::ElementOrFunction...; mapping...)
```
Simple heatmap plots of matrices.

It is a wrapper around the `plot()` function using the `rectbin` geometry.
It also applies a sane set of defaults to make sure that the plots look nice
by default. Specifically
- the aspect ratio of the coordinate system is fixed Coord.cartesian(fixed=true),
so that the rectangles become squares
- the axes run from 0.5 to N+0.5, because the first row/column is drawn to
(0.5, 1.5) and the last one to (N-0.5, N+0.5).
- the y-direction is flipped, so that the [1,1] of a matrix is in the top
left corner, as is customary
- NaNs are not drawn. `spy` leaves "holes" instead into the heatmap.

### Args:
* M: A matrix.

### Returns:
A plot object.

#### Known bugs:
   - If the matrix is only NaNs, then it throws an `ArgumentError`, because
     an empty collection gets passed to the `plot` function / `rectbin` geometry.
"""

function spy(M::AbstractMatrix, elements::ElementOrFunction...; mapping...)
    is, js, values = _findnz(x->!isnan(x), M)
    n,m = size(M)
    df = DataFrames.DataFrame(i=is, j=js, value=values)
    plot(df, x=:j, y=:i, color=:value,
        Coord.cartesian(yflip=true, fixed=true, xmin=0.5, xmax=m+.5, ymin=0.5, ymax=n+.5),
        Scale.color_continuous,
        Geom.rectbin,
        Scale.x_continuous,
        Scale.y_continuous,
        elements...; mapping...)
end

# Finds the subscripts and values where the predicate returns true.
#
# It takes a predicate (`testf`), a matrix (`A`) and returns a tuple `(is, js, zs)`,
# where `is`,'js' and 'zs' are arrays of subscripts and values where the predicate
# returned true.
#
# This function is used by spy()
# Hopefully at some point something like this will be in the standard library
# and then this can be removed (https://github.com/JuliaLang/julia/pull/9340).
#
function _findnz{T}(testf::Function, A::AbstractMatrix{T})
    N = Base.count(testf, A)
    is = zeros(Int, N)
    js = zeros(Int, N)
    zs = Array(T, N)
    if N == 0
        return (is, js, zs)
    end
    count = 1
    for j=1:size(A,2), i=1:size(A,1)
        Aij = A[i,j]
        if testf(Aij)
            is[count] = i
            js[count] = j
            zs[count] = Aij
            count += 1
        end
    end
    return (is, js, zs)
end
