#Is this usable data?
function isconcrete{T<:Number}(x::T)
    !isna(x) && isfinite(x)
end


function isconcrete(x::MathConst)
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


# TODO: Delete when 0.3 compatibility is dropped
if VERSION < v"0.4-dev"
    using Dates

    function Showoff.showoff{T <: Union(Date, DateTime)}(ds::AbstractArray{T}, style=:none)
        years = Set()
        months = Set()
        days = Set()
        hours = Set()
        minutes = Set()
        seconds = Set()
        for d in ds
            push!(years, Dates.year(d))
            push!(months, Dates.month(d))
            push!(days, Dates.day(d))
            push!(hours, Dates.hour(d))
            push!(minutes, Dates.minute(d))
            push!(seconds, Dates.second(d))
        end
        all_same_year         = length(years)   == 1
        all_one_month         = length(months)  == 1 && 1 in months
        all_one_day           = length(days)    == 1 && 1 in days
        all_zero_hour         = length(hours)   == 1 && 0 in hours
        all_zero_minute       = length(minutes) == 1 && 0 in minutes
        all_zero_seconds      = length(minutes) == 1 && 0 in minutes
        all_zero_milliseconds = length(minutes) == 1 && 0 in minutes

        # first label format
        label_months = false
        label_days = false
        f1 = "u d, yyyy"
        f2 = ""
        if !all_zero_seconds
            f2 = "HH:MM:SS.sss"
        elseif !all_zero_seconds
            f2 = "HH:MM:SS"
        elseif !all_zero_hour || !all_zero_minute
            f2 = "HH:MM"
        else
            if !all_one_day
                first_label_format = "u d yyyy"
            elseif !all_one_month
                first_label_format = "u yyyy"
            elseif !all_one_day
                first_label_format = "yyyy"
            end
        end
        if f2 != ""
            first_label_format = string(f1, " ", f2)
        else
            first_label_format = f1
        end

        labels = Array(String, length(ds))
        labels[1] = Dates.format(ds[1], first_label_format)
        d_last = ds[1]
        for (i, d) in enumerate(ds[2:end])
            if Dates.year(d) != Dates.year(d_last)
                if all_one_day && all_one_month
                    f1 = "yyyy"
                elseif all_one_day && !all_one_month
                    f1 = "u yyyy"
                else
                    f1 = "u d, yyyy"
                end
            elseif Dates.month(d) != Dates.month(d_last)
                f1 = all_one_day ? "u" : "u d"
            elseif Dates.day(d) != Dates.day(d_last)
                f1 = "d"
            else
                f1 = ""
            end

            if f2 != ""
                f = string(f1, " ", f2)
            elseif f1 != ""
                f = f1
            else
                f = first_label_format
            end

            labels[i+1] = Dates.format(d, f)
            d_last = d
        end

        return labels
    end
else
    using Base.Dates
end


# TODO: This is a clusterfuck. I should really just wrap Date types to force
# them to behave how I want.

if !method_exists(/, (Dates.Day, Dates.Day))
    /(a::Dates.Day, b::Dates.Day) = a.value / b.value
end

if VERSION < v"0.4.0-dev"
    Base.convert(::Type{Dates.Millisecond}, d::Dates.Day) =
        Dates.Millisecond(24 * 60 * 60 * 1000 * Dates.value(d))
end

if !method_exists(/, (Dates.Day, Real))
    /(a::Dates.Day, b::Real) = Dates.Day(round(Integer, (a.value / b)))
end
/(a::Dates.Day, b::FloatingPoint) = convert(Dates.Millisecond, a) / b

if !method_exists(/, (Dates.Millisecond, Dates.Millisecond))
    /(a::Dates.Millisecond, b::Dates.Millisecond) = a.value / b.value
end

if !method_exists(/, (Dates.Millisecond, Real))
    /(a::Dates.Millisecond, b::Real) = Dates.Millisecond(round(Integer, (a.value / b)))
end
/(a::Dates.Millisecond, b::FloatingPoint) = Dates.Millisecond(round(Integer, (a.value / b)))


if !method_exists(-, (Dates.Date, Dates.DateTime))
    -(a::Dates.Date, b::Dates.DateTime) = convert(Dates.DateTime, a) - b
end

+(a::Dates.Date, b::Dates.Millisecond) = convert(Dates.DateTime, a) + b

if !method_exists(-, (Dates.DateTime, Dates.Date))
    -(a::Dates.DateTime, b::Dates.Date) = a - convert(Dates.DateTime, b)
end


if !method_exists(/, (Dates.Day, Dates.Millisecond))
    /(a::Dates.Day, b::Dates.Millisecond) = convert(Dates.Millisecond, a) / b
end

for T in [Dates.Hour, Dates.Minute, Dates.Second, Dates.Millisecond]
    if !method_exists(-, (Dates.Date, T))
        @eval begin
            -(a::Dates.Date, b::$(T)) = convert(Dates.DateTime, a) - b
        end
    end
end


#if !method_exists(*, (FloatingPoint, Dates.Day))
    *(a::FloatingPoint, b::Dates.Day) = Dates.Day(round(Integer, (a * b.value)))
    *(a::Dates.Day, b::FloatingPoint) = b * a
    *(a::FloatingPoint, b::Dates.Millisecond) = Dates.Millisecond(round(Integer, (a * b.value)))
    *(a::Dates.Millisecond, b::FloatingPoint) = b * a
#end


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
    if color(a) < color(b)
        return true
    elseif color(a) == color(b)
        return a.alpha < b.alpha
    else
        return false
    end
end


function group_color_isless{S, T <: Color}(a::(@compat Tuple{S, T}),
                                                b::(@compat Tuple{S, T}))
    if a[1] < b[1]
        return true
    elseif a[1] == b[1]
        return color_isless(a[2], b[2])
    else
        return false
    end
end


