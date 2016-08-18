#Is this usable data?
function isconcrete{T<:Number}(x::T)
    !isna(x) && isfinite(x)
end


function isconcrete(x::(@compat Irrational))
    return true
end


function isconcrete(x)
    !isna(x)
end


function hasna(xs)
    return false
end


function hasna(xs::AbstractDataArray)
    for x in xs
        if isna(x)
            return true
        end
    end
    return false
end



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

    yss = Array(AbstractVector, length(xss))
    for (i, xs) in enumerate(xss)
        yss[i] = Array(eltype(xs), count)
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

function concrete_length{T}(xs::DataArray{T})
    n = 0
    for i = 1:length(xs)
        if !xs.na[i] && isconcrete(xs.data[i]::T)
            n += 1
        end
    end
    n
end

function concrete_length(xs::Iterators.Chain)
    n = 0
    for obj in xs.xss
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


function concrete_minmax{T<:Real}(xs, xmin::T, xmax::T)
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


function concrete_minmax{T<:Real, TA}(xs::DataArray{TA}, xmin::T, xmax::T)
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


function concrete_minmax{T}(xs, xmin::T, xmax::T)
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


function concrete_minmax{T, TA}(xs::DataArray{TA}, xmin::T, xmax::T)
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


function concrete_minmax{T<:Real}(xs::Iterators.Chain, xmin::T, xmax::T)
    for obj in xs.xss
        xmin, xmax = concrete_minmax(obj, xmin, xmax)
    end
    xmin, xmax
end



function nonzero_length(xs)
    n = 0
    for x in xs
        if x != 0
            n += 1
        end
    end
    n
end


# Create a new object of type T from a with missing values (i.e., those set to
# nothing) inherited from b.
function inherit{T}(a::T, b::T)
    c = copy(a)
    inherit!(c, b)
    c
end


function inherit!{T}(a::T, b::T)
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


isnothing(u) = is(u, nothing)
issomething(u) = !isnothing(u)

negate(f) = x -> !f(x)


function has{T,N}(xs::AbstractArray{T,N}, y::T)
    for x in xs
        if x == y
            return true
        end
    end
    return false
end

Maybe(T) = @compat(Union{T, (@compat Void)})


function lerp(x::Float64, a, b)
    a + (b - a) * max(min(x, 1.0), 0.0)
end


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
is_int_compatable{T <: AbstractFloat}(x::T) = abs(x) < maxintfloat(T) && float(int(x)) == x
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
    xs = Array(typeof(a + step), n)
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


function svg_color_class_from_label(label::AbstractString)
    return @sprintf("color_%s", escape_id(label))
end


"""
A faster map function for PooledDataVector
"""
function pooled_map(T::Type, f::Function, xs::PooledDataVector)
    newpool = T[f(x) for x in xs.pool]
    return T[newpool[i] for i in xs.refs]
end

using Base.Dates

# Arbitrarily order colors
function color_isless(a::Color, b::Color)
    return color_isless(convert(RGB{Float32}, a), convert(RGB{Float32}, b))
end


function color_isless(a::TransparentColor, b::TransparentColor)
    return color_isless(convert(RGBA{Float32}, a), convert(RGBA{Float32}, b))
end


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


function group_color_isless{S, T <: Colorant}(a::(@compat Tuple{S, T}),
                                              b::(@compat Tuple{S, T}))
    if a[1] < b[1]
        return true
    elseif a[1] == b[1]
        return color_isless(a[2], b[2])
    else
        return false
    end
end


"""
trim longer arrays to the size of the smallest one
and zip the arrays.
"""
function trim_zip(xs...)
    mx = max(map(length, xs)...)
    mn = min(map(length, xs)...)
    if mx == mn
        zip(xs...)
    else
        zip([length(x) == mn ? x : x[1:mn] for x in xs]...)
    end
end
