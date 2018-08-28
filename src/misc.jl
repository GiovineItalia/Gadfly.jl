#Is this usable data?
isconcrete(x::T) where {T<:Number} = !ismissing(x) && isfinite(x)
isconcrete(x::(Irrational)) = true
isconcrete(x) = !ismissing(x)

function isallconcrete(xs)
    ans = true
    for x in xs
        if !isconcrete(x)
            ans = false
            break
        end
    end
    return ans
end


function concretize(xss::AbstractVector...)
    if all(map(isallconcrete, xss))
        return xss
    end

    count = 0
    for j in 1:length(xss[1])
        for xs in xss
            if !isconcrete(xs[j])
                @goto next_j1
            end
        end

        count += 1
        @label next_j1
    end

    yss = Array{AbstractVector}(length(xss))
    for (i, xs) in enumerate(xss)
        yss[i] = Array{eltype(xs)}(count)
    end

    k = 1
    for j in 1:length(xss[1])
        for xs in xss
            if !isconcrete(xs[j])
                @goto next_j2
            end
        end

        for (i, xs) in enumerate(xss)
            yss[i][k] = xs[j]
        end
        k += 1

        @label next_j2
    end

    return tuple(yss...)
end


# How many concrete elements in an iterable
function concrete_length(xs)
    n = 0
    for x in xs
        if isconcrete(x)
            n += 1
        end
    end
    n
end

function concrete_length(xs::DataArray{T}) where T
    n = 0
    for i = 1:length(xs)
        if !xs.na[i] && isconcrete(xs.data[i]::T)
            n += 1
        end
    end
    n
end

function concrete_length(xs::Iterators.Flatten)
    n = 0
    for obj in xs.it
        n += concrete_length(obj)
    end
    n
end

function concrete_minimum(xs)
    if done(xs, start(xs))
        error("argument must not be empty")
    end

    x_min = first(xs)
    for x in xs
        if Gadfly.isconcrete(x) && isfinite(x)
            x_min = x
            break
        end
    end

    for x in xs
        if Gadfly.isconcrete(x) && isfinite(x) && x < x_min
            x_min = x
        end
    end
    return x_min
end


function concrete_maximum(xs)
    if done(xs, start(xs))
        error("argument must not be empty")
    end

    x_max = first(xs)
    for x in xs
        if Gadfly.isconcrete(x) && isfinite(x)
            x_max = x
            break
        end
    end

    for x in xs
        if Gadfly.isconcrete(x) && isfinite(x) && x > x_max
            x_max = x
        end
    end
    return x_max
end


function concrete_minmax(xs, xmin::T, xmax::T) where T<:Real
    if eltype(xs) <: Base.Callable
        return xmin, xmax
    end

    for x in xs
        if isconcrete(x)
            xT = convert(T, x)
            if isnan(xmin) || xT < xmin
                xmin = xT
            end
            if isnan(xmax) || xT > xmax
                xmax = xT
            end
        end
    end
    xmin, xmax
end


function concrete_minmax(xs::DataArray{TA}, xmin::T, xmax::T) where {T<:Real, TA}
    for i = 1:length(xs)
        if !xs.na[i]
            x = xs.data[i]::TA
            xT = convert(T, x)
            if isnan(xmin) || xT < xmin
                xmin = xT
            end
            if isnan(xmax) || xT > xmax
                xmax = xT
            end
        end
    end
    xmin, xmax
end


function concrete_minmax(xs, xmin::T, xmax::T) where T
    for x in xs
        if isconcrete(x)
            xT = convert(T, x)
            if xT < xmin
                xmin = xT
            end
            if xT > xmax
                xmax = xT
            end
        end
    end
    xmin, xmax
end


function concrete_minmax(xs::DataArray{TA}, xmin::T, xmax::T) where {T, TA}
    for i = 1:length(xs)
        if !xs.na[i]
            x = xs.data[i]::TA
            xT = convert(T, x)
            if xT < xmin
                xmin = xT
            end
            if xT > xmax
                xmax = xT
            end
        end
    end
    xmin, xmax
end


function concrete_minmax(xs::Iterators.Flatten, xmin::T, xmax::T) where T<:Real
    for obj in xs.it
        xmin, xmax = concrete_minmax(obj, xmin, xmax)
    end
    xmin, xmax
end


# Create a new object of type T from a with missing values (i.e., those set to
# nothing) inherited from b.
function inherit(a::T, b::T) where T
    c = copy(a)
    inherit!(c, b)
    c
end


function inherit!(a::T, b::T) where T
    for field in fieldnames(T)
        aval = getfield(a, field)
        bval = getfield(b, field)
        # TODO: this is a hack to let non-default labelers overide the defaults
        if aval === nothing || aval === string || aval == showoff
            setfield!(a, field, bval)
        elseif typeof(aval) <: Dict && typeof(bval) <: Dict
            merge!(aval, getfield(b, field))
        end
    end
    nothing
end


isnothing(u) = u === nothing
issomething(u) = !isnothing(u)

negate(f) = x -> !f(x)


function has(xs::AbstractArray{T,N}, y::T) where {T,N}
    for x in xs
        if x == y
            return true
        end
    end
    return false
end

Maybe(T) = Union{T, (Void)}


lerp(x::Float64, a, b) = a + (b - a) * max(min(x, 1.0), 0.0)


# Generate a unique id, primarily for assigning IDs to SVG elements.
let next_unique_svg_id_num = 0
    global unique_svg_id
    function unique_svg_id()
        uid = @sprintf("id%d", next_unique_svg_id_num)
        next_unique_svg_id_num += 1
        uid
    end
end


# Remove any markup or whitespace from a string.
function escape_id(s::AbstractString)
    s = replace(s, r"<[^>]*>", "")
    s = replace(s, r"\s", "_")
    s
end


# Can a numerical value be treated as an integer
is_int_compatable(::Integer) = true
is_int_compatable(x::T) where {T <: AbstractFloat} = abs(x) < maxintfloat(T) && float(int(x)) == x
is_int_compatable(::Any) = false


## Return a DataFrame with x, y column suitable for plotting a function.
#
# Args:
#  f: Function/Expression to be evaluated.
#  a: Lower bound.
#  b: Upper bound.
#  n: Number of points to evaluate the function at.
#
# Returns:
#  A data frame with "x" and "f(x)" columns.
#
function evalfunc(f::Function, a, b, n)
    @assert n > 1

    step = (b - a) / (n - 1)
    xs = Array{typeof(a + step)}(n)
    for i in 1:n
        xs[i] = a + (i-1) * step
    end

    df = DataFrame(xs, map(f, xs))
    # NOTE: 'colnames!' is the older deprecated name. 'names!' was also defined
    # but threw an error.
    try
        names!(df, [:x, :f_x])
    catch
        colnames!(df, ["x", "f_x"])
    end
    df
end


# Construct a jscall to store arbitrary data in the element
function jsdata(key::AbstractString, value::AbstractString, arg::Vector{Measure}=Measure[])
    return jscall(
        """
        data("$(escape_string(key))", $(value))
        """, arg)
end


# Construct jscall properties to store arbitrary data in plotroot elements.
function jsplotdata(key::AbstractString, value::AbstractString, arg::Vector{Measure}=Measure[])
    return jscall(
        """
        plotroot().data("$(escape_string(key))", $(value))
        """, arg)
end


svg_color_class_from_label(label::AbstractString) = @sprintf("color_%s", escape_id(label))

using Base.Dates

# Arbitrarily order colors
color_isless(a::Color, b::Color) =
        color_isless(convert(RGB{Float32}, a), convert(RGB{Float32}, b))
color_isless(a::TransparentColor, b::TransparentColor) =
        color_isless(convert(RGBA{Float32}, a), convert(RGBA{Float32}, b))


function color_isless(a::RGB{Float32}, b::RGB{Float32})
    if a.r < b.r
        return true
    elseif a.r == b.r
        if a.g < b.g
            return true
        elseif a.g == b.g
            return a.b < b.b
        else
            return false
        end
    else
        return false
    end
end


function color_isless(a::RGBA{Float32}, b::RGBA{Float32})
    if color_isless(color(a), color(b))
        return true
    elseif color(a) == color(b)
        return a.alpha < b.alpha
    else
        return false
    end
end


function group_color_isless(a::(Tuple{S, T}),
                            b::(Tuple{S, T})) where {S, T <: Colorant}
    if a[1] < b[1]
        return true
    elseif a[1] == b[1]
        return color_isless(a[2], b[2])
    else
        return false
    end
end


#trim longer arrays to the size of the smallest one
#and zip the arrays.
function trim_zip(xs...)
    mx = max(map(length, xs)...)
    mn = min(map(length, xs)...)
    if mx == mn
        zip(xs...)
    else
        zip([length(x) == mn ? x : x[1:mn] for x in xs]...)
    end
end

# Convenience constructors of IndirectArrays
discretize_make_ia(values::AbstractVector, levels) = IndirectArray(indexin(values, levels), levels)
discretize_make_ia(values::AbstractVector)         = discretize_make_ia(values, unique(values))
discretize_make_ia(values::AbstractVector, ::Void) = discretize_make_ia(values)

discretize_make_ia(values::IndirectArray)         = values
discretize_make_ia(values::IndirectArray, ::Void) = values

discretize_make_ia(values::CategoricalArray) =
    discretize_make_ia(values, intersect(push!(levels(values), missing), unique(values)))
discretize_make_ia(values::CategoricalArray, ::Void) = discretize_make_ia(values)
function discretize_make_ia(values::CategoricalArray{T}, levels::Vector) where {T}
    mapping = coalesce.(indexin(CategoricalArrays.index(values.pool), levels), 0)
    unshift!(mapping, coalesce(findfirst(ismissing, levels), 0))
    index = [mapping[x+1] for x in values.refs]
    any(iszero, index) && throw(ArgumentError("values not in levels encountered"))
    return IndirectArray(index, convert(Vector{T},levels))
end
function discretize_make_ia(values::CategoricalArray{T}, levels::CategoricalVector{T}) where T
    _levels = map!(t -> ismissing(t) ? t : get(t), Vector{T}(length(levels)), levels)
    discretize_make_ia(values, _levels)
end
