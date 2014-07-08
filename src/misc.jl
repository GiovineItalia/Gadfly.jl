
# Work around differences in julia 0.2 and 0.3 set constructors.
function set(T::Type, itr)
    S = Set{T}()
    union!(S, itr)
end

function set(itr)
    set(Any, itr)
end


# Is this usable data?
function isconcrete{T<:Number}(x::T)
    !isna(x) && isfinite(x)
end

function isconcrete(x::MathConst)
    return true
end

function isconcrete(x)
    !isna(x)
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
        if !xs.na[i] && isfinite(xs.data[i]::T)
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


function default_formatter(xs)
    [string(x) for x in xs]
end


# Create a new object of type T from a with missing values (i.e., those set to
# nothing) inherited from b.
function inherit{T}(a::T, b::T)
    c = copy(a)
    inherit!(c, b)
    c
end


function inherit!{T}(a::T, b::T)
    for field in T.names
        aval = getfield(a, field)
        bval = getfield(b, field)
        # TODO: this is a hack to let non-default labelers overide the defaults
        if aval === nothing || aval === string || aval == default_formatter
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

Maybe(T) = Union(T, Nothing)


function lerp(x::Float64, a::Float64, b::Float64)
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
function escape_id(s::String)
    s = replace(s, r"<[^>]*>", "")
    s = replace(s, r"\s", "_")
    s
end


# Can a numerical value be treated as an integer
is_int_compatable(::Integer) = true
is_int_compatable{T <: FloatingPoint}(x::T) = abs(x) < maxintfloat(T) && float(int(x)) == x
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
function jsdata(key::String, value::String, arg::Vector{Measure}=Measure[])
    return jscall(
        """
        data("$(escape_string(key))", $(value))
        """, arg)
end


# Construct jscall properties to store arbitrary data in plotroot elements.
function jsplotdata(key::String, value::String, arg::Vector{Measure}=Measure[])
    return jscall(
        """
        plotroot().data("$(escape_string(key))", $(value))
        """, arg)
end


function svg_color_class_from_label(label::String)
    return @sprintf("color_%s", escape_id(label))
end


