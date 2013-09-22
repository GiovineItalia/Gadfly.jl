


# Print a floating point number at fixed precision. Pretty much equivalent to
# @sprintf("%0.$(precision)f", x), without the macro issues.
function format_fixed(x::FloatingPoint, precision::Integer)
    @assert precision >= 0

    if x == Inf
        return "∞"
    elseif x == -Inf
        return "-∞"
    elseif x == NaN
        return "NaN"
    end

    Base.Grisu.@grisu_ccall x Base.Grisu.FIXED precision
    point, len, digits = (Base.Grisu.POINT[1], Base.Grisu.LEN[1], Base.Grisu.DIGITS)
    ss = Uint8[]
    if x < 0
        push!(ss, '-')
    end

    append!(ss, digits[1:min(point, len)])

    if point > len
        for _ in len:point-1
            push!(ss, '0')
        end
    elseif point < len
        if point <= 0
            push!(ss, '0')
        end
        push!(ss, '.')
        if point < 0
            for _ in 1:-point
                push!(ss, '0')
            end
            append!(ss, digits[1:len])
        else
            append!(ss, digits[point+1:len])
        end
    end

    trailing_zeros = precision - max(0, len - point)
    if trailing_zeros > 0 && point >= len
        push!(ss, '.')
    end

    for _ in 1:trailing_zeros
        push!(ss, '0')
    end

    bytestring(ss)
end


# Print a floating point number in scientific notation at fixed precision. Sort of equivalent
# to @sprintf("%0.$(precision)e", x), but prettier printing.
function format_fixed_scientific(x::FloatingPoint, precision::Integer)
    if x == 0.0
        return "0"
    elseif x == Inf
        return "∞"
    elseif x == -Inf
        return "-∞"
    elseif x == NaN
        return "NaN"
    end

    Base.Grisu.@grisu_ccall x Base.Grisu.FIXED precision
    point, len, digits = (Base.Grisu.POINT[1], Base.Grisu.LEN[1], Base.Grisu.DIGITS)

    @assert len > 0

    ss = Uint8[]
    if x < 0
        push!(ss, '-')
    end

    push!(ss, digits[1])
    if precision > 1
        push!(ss, '.')
    end

    for i in 2:len
        push!(ss, digits[i])
    end

    for i in (len+1):precision
        push!(ss, '0')
    end

    string(bytestring(ss), "×10<sup>$(point)</sup>")
end


# Nicely format an print some numbers.
function formatter(xs::FloatingPoint...; fmt=:auto)
    # figure out the lowest suitable precision
    delta = Inf
    for (x0, x1) in zip(xs, xs[2:end])
        delta = min(delta, abs(x1 - x0))
    end
    x_min, x_max = min(xs), max(xs)

    if fmt == :auto && abs(log10(x_max - x_min)) > 3
        fmt = :scientific
    else
        fmt = :plain
    end

    if fmt == :plain
        # SHORTEST_SINGLE rather than SHORTEST to crudely round away tiny innacuracies
        Base.Grisu.@grisu_ccall delta Base.Grisu.SHORTEST_SINGLE 0
        precision = max(0, Base.Grisu.LEN[1] - Base.Grisu.POINT[1])

        return x -> format_fixed(x, precision)
    elseif fmt == :scientific
        Base.Grisu.@grisu_ccall delta Base.Grisu.SHORTEST_SINGLE 0
        delta_magnitude = Base.Grisu.POINT[1]

        Base.Grisu.@grisu_ccall x_max Base.Grisu.SHORTEST_SINGLE 0
        x_max_magnitude = Base.Grisu.POINT[1]

        precision = 1 + max(0, x_max_magnitude - delta_magnitude)

        return x -> format_fixed_scientific(x, precision)
    end
end


