


# Print a floating point number at fixed precision. Pretty much equivalent to
# @sprintf("%0.$(precision)f", x), without the macro issues.
function format_fixed(x::AbstractFloat, precision::Integer)
    @assert precision >= 0

    if x == Inf
        return "∞"
    elseif x == -Inf
        return "-∞"
    elseif isnan(x)
        return "NaN"
    end

    Base.Grisu.@grisu_ccall x Base.Grisu.FIXED precision
    point, len, digits = (Base.Grisu.POINT[1], Base.Grisu.LEN[1], Base.Grisu.DIGITS)
    ss = UInt8[]
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

    Compat.String(ss)
end


# Print a floating point number in scientific notation at fixed precision. Sort of equivalent
# to @sprintf("%0.$(precision)e", x), but prettier printing.
function format_fixed_scientific(x::AbstractFloat, precision::Integer,
                                 engineering::Bool)
    if x == 0.0
        return "0"
    elseif x == Inf
        return "∞"
    elseif x == -Inf
        return "-∞"
    elseif isnan(x)
        return "NaN"
    end

    mag = log10(abs(x))
    if mag < 0
        grisu_precision = precision + abs(iround(mag))
    else
        grisu_precision = precision
    end

    Base.Grisu.@grisu_ccall x Base.Grisu.FIXED grisu_precision
    point, len, digits = (Base.Grisu.POINT[1], Base.Grisu.LEN[1], Base.Grisu.DIGITS)

    @assert len > 0

    ss = Char[]
    if x < 0
        push!(ss, '-')
    end

    push!(ss, digits[1])
    nextdigit = 2
    if engineering
        while (point - 1) % 3 != 0
            if nextdigit <= len
                push!(ss, digits[nextdigit])
            else
                push!(ss, '0')
            end
            nextdigit += 1
            point -= 1
        end
    end

    if precision > 1
        push!(ss, '.')
    end

    for i in nextdigit:len
        push!(ss, digits[i])
    end

    for i in (len+1):precision
        push!(ss, '0')
    end

    string(utf8(ss), "×10<sup>$(point - 1)</sup>")
end


formatter() = string


# Nicely format an print some numbers.
function formatter{T<:AbstractFloat}(xs::AbstractArray{T}; fmt=:auto)
    if length(xs) <= 1
        return string
    end

    # figure out the lowest suitable precision
    delta = Inf
    finite_xs = filter(isfinite, xs)
    for (x0, x1) in zip(finite_xs, drop(finite_xs, 1))
        delta = min(x1 - x0, delta)
    end
    x_min, x_max = concrete_minimum(xs), concrete_maximum(xs)

    x_min, x_max, delta = (float64(float32(x_min)), float64(float32(x_max)), 
        float64(float32(delta)))

    if !isfinite(x_min) || !isfinite(x_max) || !isfinite(delta)
        error("At least one finite value must be provided to formatter.")
    end

    if fmt == :auto
        if abs(log10(x_max - x_min)) > 4
            fmt = :scientific
        else
            fmt = :plain
        end
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

        return x -> format_fixed_scientific(x, precision, false)
    elseif fmt == :engineering
        Base.Grisu.@grisu_ccall delta Base.Grisu.SHORTEST_SINGLE 0
        delta_magnitude = Base.Grisu.POINT[1]

        Base.Grisu.@grisu_ccall x_max Base.Grisu.SHORTEST_SINGLE 0
        x_max_magnitude = Base.Grisu.POINT[1]

        precision = 1 + max(0, x_max_magnitude - delta_magnitude)

        return x -> format_fixed_scientific(x, precision, true)
    else
        error("$(fmt) is not a recongnized number format")
    end
end


# Print dates
function formatter{T<:Date}(ds::AbstractArray{T}; fmt=nothing)
    if isa(fmt, Function)
        return fmt
    end

    const month_names = [
        "January", "February", "March", "April", "May", "June", "July",
        "August", "September", "October", "November", "December"
    ]

    const month_abbrevs = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]

    day_all_1   = all(map(d -> day(d) == 1, ds))
    month_all_1 = all(map(d -> month(d) == 1, ds))
    years = Set()
    for d in ds
        push!(years, year(d))
    end

    if day_all_1 && month_all_1
        # only label years
        function format(d)
            buf = IOBuffer()
            print(buf, year(d))
            takebuf_string(buf)
        end
    elseif day_all_1
        # label months and years
        function format(d)
            buf = IOBuffer()
            if d == ds[1] || month(d) == 1
                print(buf, month_abbrevs[month(d)], " ", year(d))
            else
                print(buf, month_abbrevs[month(d)])
            end
            takebuf_string(buf)
        end
    else
        function format(d)
            buf = IOBuffer()
            if d == ds[1] || (month(d) == 1 && day(d) == 1)
                print(buf, month_abbrevs[month(d)], " ", day(d), " ", year(d))
            elseif day(d) == 1
                print(buf, month_abbrevs[month(d)], " ", day(d))
            else
                print(buf, day(d))
            end
            takebuf_string(buf)
        end
    end
end


# Catchall
function formatter(xs::AbstractArray; fmt=nothing)
    function format(x)
        buf = IOBuffer()
        print(buf, x)
        takebuf_string(buf)
    end

    format
end

