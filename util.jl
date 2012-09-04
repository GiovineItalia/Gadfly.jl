

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


# itertools

type Count
    start::Any
    step::Any
end

count(start, step)           = Count(start, step)
count{T <: Number}(start::T) = Count(start, convert(T, 1))
count()                      = Count(0, 1)

start(it::Count) = it.start
next(it::Count, state) = (state, state + 1)
done(it::Count, state) = false
length(it::Count) = nothing


type Cycle
    xs::Any
end

cycle(xs) = Cycle(xs)

start(it::Cycle) = start(it.xs)

function next(it::Cycle, state)
    if done(it.xs, state)
        state = start(it.xs)
    end
    v = next(it.xs, state)
end

done(it::Cycle, state) = length(state) == 0
length(it::Count) = nothing


type Chain
    xss::Vector{Any}
    function Chain(xss...)
        new({xss...})
    end
end

chain(xss...) = Chain(xss...)

function start(it::Chain)
    i = 1
    xs_state = nothing
    while i <= length(it.xss)
        xs_state = start(it.xss[i])
        if !done(it.xss[i], xs_state)
            break
        end
        i += 1
    end
    (i, xs_state)
end

function next(it::Chain, state)
    i, xs_state = state
    (v, xs_state) = next(it.xss[i], xs_state)
    while done(it.xss[i], xs_state)
        i += 1
        if i > length(it.xss)
            break
        end
        xs_state = start(it.xss[i])
    end
    (v, (i, xs_state))
end

done(it::Chain, state) = state[1] > length(it.xss)


type Product
    xss::Vector{Any}
    function Product(xss...)
        new({xss...})
    end
end


product(xss...) = Product(xss...)


function start(it::Product)
    js = [start(xs) for xs in it.xss]
    if any([done(xs, j) for (xs, j) in zip(it.xss, js)])
        (js, nothing)
    else
        vs = Array(Any, length(js))
        for ((xs, j), i) in enumerate(zip(it.xss, js))
            (vs[i], js[i]) = next(xs, j)
            (v, j) = next(xs, j)
            vs[i] = v
            js[i] = j
            if done(xs, js[i])
                js[i] = start(xs)
            end
        end

        (js, vs)
    end
end


function next(it::Product, state)
    (js, vs) = state
    ans = tuple(vs...)

    # increment
    n = length(it.xss)
    for i in 1:n
        if !done(it.xss[i], js[i])
            (vs[i], js[i]) = next(it.xss[i], js[i])
            break
        elseif i == n
            vs = nothing
            break
        end

        js[i] = start(it.xss[i])
        (vs[i], js[i]) = next(it.xss[i], js[i])
    end
    (ans, (js, vs))
end

done(it::Product, state) = is(state[2], nothing)


