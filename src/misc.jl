

# Create a new object of type T from a with missing values (i.e., those set to
# nothing) inherited from b.
function inherit{T}(a::T, b::T)
    c = copy(a)
    inherit!(c, b)
    c
end


function inherit!{T}(a::T, b::T)
    for field in T.names
        val = getfield(a, field)
        if val === nothing
            setfield(a, field, getfield(b, field))
        end
    end
    nothing
end


isnothing(u) = is(u, nothing)
issomething(u) = !isnothing(u)

negate(f) = x -> !f(x)

function push{T}(xs::Vector{T}, ys::T...)
    for y in ys
        push(xs, y)
    end
end


Maybe(T) = Union(T, Nothing)

