# Particularly useful or beautiful grammar of graphics invocations.

"""
    plot(fs::Vector{T}, lower::Number, upper::Number, elements::ElementOrFunction...;
         mapping...) where T <: Base.Callable
"""
function plot(fs::Vector{T}, lower::Number, upper::Number, elements::ElementOrFunction...; mapping...) where T <: Base.Callable
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

    if upper < lower
        push!(elements, Coord.cartesian(xflip=true))
    end

    mappingdict = Dict{Symbol, Any}(:y => fs, :xmin => [lower], :xmax => [upper])
    for (k, v) in mapping
        mappingdict[k] = v
    end

    plot(Stat.func, Geom.line, elements...; mappingdict...)
end


"""
    plot(f::Function, lower::Number, upper::Number, elements::ElementOrFunction...;
         mapping...)

Plot the function or expression `f`, which takes a single
argument or operates on a single variable, respectively, between the `lower`
and `upper` bounds.  See [`Stat.func`](@ref) and [`Geom.line`](@ref).
"""
plot(f::Function, lower::Number, upper::Number, elements::ElementOrFunction...; mapping...) =
        plot(Function[f], lower, upper, elements...; mapping...)


"""
    plot(f::Function, xmin::Number, xmax::Number, ymin::Number, ymax::Number,
         elements::ElementOrFunction...; mapping...)

Plot the contours of the 2D function or expression in `f`.
See [`Stat.func`](@ref) and [`Geom.contour`](@ref).
"""
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
        push!(default_elements, Guide.colorkey(title="f(x,y)"))
    end

    push!(default_elements, Coord.cartesian(xflip=xmin > xmax, yflip=ymin > ymax))

    plot(layer(f, xmin, xmax, ymin, ymax,
               elements...; mapping...), default_elements...)
end


"""
    layer(fs::Vector{T}, lower::Number, upper::Number,
          elements::ElementOrFunction...) where T <: Base.Callable -> [Layers]

Create a layer from a list of functions or expressions in `fs`.
"""
layer(fs::Vector{T}, lower::Number, upper::Number, elements::ElementOrFunction...) where T <: Base.Callable =
    layer(y=fs, xmin=[lower], xmax=[upper], Stat.func, Geom.line, elements...)

"""
    layer(f::Function, lower::Number, upper::Number,
          elements::ElementOrFunction...) -> [Layers]

Create a layer from the function or expression `f`, which takes a single
argument or operates on a single variable, respectively, between the `lower`
and `upper` bounds.  See [`Stat.func`](@ref) and [`Geom.line`](@ref).
"""
layer(f::Function, lower::Number, upper::Number, elements::ElementOrFunction...) =
        layer(Function[f], lower, upper, elements...)

"""
    layer(f::Function, xmin::Number, xmax::Number, ymin::Number, ymax::Number,
          elements::ElementOrFunction...; mapping...) -> [Layers]

Create a layer of the contours of the 2D function or expression in `f`.
See [`Stat.func`](@ref) and [`Geom.contour`](@ref).
"""
function layer(f::Function, xmin::Number, xmax::Number, ymin::Number, ymax::Number,
               elements::ElementOrFunction...; mapping...)
    if isempty(elements)
        elements = ElementOrFunction[]
    elseif isa(elements, Tuple)
        elements = ElementOrFunction[elements...]
    end

    mappingdict = Dict{Symbol, Any}(:z => f,
                                    :xmin => [xmin], :xmax => [xmax],
                                    :ymin => [ymin], :ymax => [ymax])
    for (k, v) in mapping
        mappingdict[k] = v
    end

    layer(Geom.contour, elements...; mappingdict...)
end


### why `spy` and not `plot`?
"""
    spy(M::AbstractMatrix, elements::ElementOrFunction...; mapping...) -> Plot

Plots a heatmap of `M`, with M[1,1] in the upper left.  `NaN` values are
left blank, and an error is thrown if all elements of `M` are `NaN`.  See
[`Geom.rectbin`](@ref) and [`Coord.cartesian(fixed=true)...)`](@ref
Gadfly.Coord.cartesian).
"""
function spy(M::AbstractMatrix, elements::ElementOrFunction...; mapping...)
    is, js, values = _findnz(x->!isnan(x), M)
    n,m = size(M)
    plot(x=js, y=is, color=values,
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
function _findnz(testf::Function, A::AbstractMatrix{T}) where T
    N = Base.count(testf, A)
    is = zeros(Int, N)
    js = zeros(Int, N)
    zs = Array{T}(undef, N)
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
