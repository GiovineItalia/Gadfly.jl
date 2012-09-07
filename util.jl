

# Create a new object of type T from a with missing values (i.e., those set to
# nothing) inherited from b.
function inherit{T}(a::T, b::T)
    c = copy(a)
    for field in T.names
        val = getfield(c, field)
        if is(val, nothing)
            setfield(c, field, getfield(b, field))
        end
    end
    c
end


isnothing(u) = is(u, nothing)
issomething(u) = !isnothing(u)

