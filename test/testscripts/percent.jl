using Gadfly

set_default_plot_size(6inch, 6inch)

import Base: convert, show, +, -, /, *, isless, one, zero, isfinite

struct Percent
    value::Float64
end

# Functions necessary for plotting

+(a::Percent, b::Percent) = Percent(a.value + b.value)
-(a::Percent, b::Percent) = Percent(a.value - b.value)
-(a::Percent) = Percent(-a.value)
*(a::Percent, b::Float64) = Percent(a.value * b)
*(a::Float64, b::Percent) = Percent(a * b.value)

# Must return something that can be converted to Float64 with float64(a/b)
/(a::Percent, b::Percent) = a.value / b.value

isless(a::Percent, b::Percent) = isless(a.value, b.value)
one(::Type{Percent}) = Percent(0.01)
zero(::Type{Percent}) = Percent(0.0)
isfinite(a::Percent) = isfinite(a.value)
convert(::Type{Float64}, x::Percent) = x.value
show(io::IO, p::Percent) = print(io, round(100 * p.value, digits=4), "%")

y=[Percent(0.1), Percent(0.2), Percent(0.3)]
plot(x=collect(1:length(y)), y=y)
