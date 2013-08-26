

# Is this usable data?
function isconcrete{T<:Number}(x::T)
    !isna(x) && isfinite(x)
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
    for field in T.names
        aval = getfield(a, field)
        bval = getfield(b, field)
        # TODO: this is a hack to let non-default labelers overide the defaults
        if aval === nothing || aval === string || aval === fmt_float
            setfield(a, field, bval)
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


function push!{T}(xs::Vector{T}, ys::T...)
    for y in ys
        push!(xs, y)
    end
end


Maybe(T) = Union(T, Nothing)


# Float64 -> String, trimming trailing zeros when appropriate.
# This is largely taken from cairo's function _cairo_dtostr.
function fmt_float(x::Float64)
    if x < 0.1
        a = @sprintf("%0.4f", x)
    else
        a = @sprintf("%f", x)
    end

    n = length(a)
    while a[n] == '0'
        n -= 1
    end

    if a[n] == '.'
        n -= 1
    end

    a[1:n]
end


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
    s = replace(s, r" ", "_")
    s
end


# Can a numerical value be treated as an integer
is_int_compatable(::Integer) = true
is_int_compatable{T <: FloatingPoint}(x::T) = abs(x) < maxintfloat(T) && float(int(x)) == x
is_int_compatable(::Any) = false

