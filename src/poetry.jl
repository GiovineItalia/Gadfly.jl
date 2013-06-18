
# Particularly useful or beautiful grammar of graphics invocations.

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
    xs = [x for x in a:(b - a)/n:b]
    df = DataFrame(xs, map(f, xs))
    colnames!(df, ["x", "f(x)"])
    df
end


evalfunc(f::Expr, a, b, n) = evalfunc(eval(:(x -> $f)), a, b, n)


# A convenience plot function for quickly plotting functions are expressions.
#
# Args:
#   fs: An array in which each object is either a single argument function or an
#       expression computing some value on x.
#   a: Lower bound on x.
#   b: Upper bound on x.
#   elements: One ore more grammar elements.
#
# Returns:
#   A plot objects.
#
function plot(fs::Array, a, b, elements::Element...)
    df = DataFrame()
    for (i, f) in enumerate(fs)
        df_i = evalfunc(f, a, b, 250)
        name = typeof(f) == Expr ? string(f) : @sprintf("f<sub>%d</sub>", i)
        df_i = cbind(df_i, [name for _ in 1:size(df_i)[1]])
        colnames!(df_i, ["x", "f(x)", "f"])
        df = rbind(df, df_i)
    end

    mapping = {:x => "x", :y => "f(x)"}
    if length(fs) > 1
        mapping[:color] = "f"
    end

    plot(df, mapping, Geom.line, elements...)
end


# Plot a single function.
function plot(f::Function, a, b, elements::Element...)
    plot([f], a, b, elements...)
end


# Plot a single expression.
function plot(f::Expr, a, b, elements::Element...)
    plot([f], a, b, elements...)
end


# Plot an expression from a to b.
macro plot(expr, a, b)
    quote
        plot(x -> $(expr), $(a), $(b))
    end
end


# Simple heatmap plots of matrices.
#
# Args:
#   M: A matrix.
#
# Returns:
#   A plot object.
#
function spy(M)
    is, js, values = findn_nzs(M)
    df = DataFrame({"i" => is, "j" => js, "value" => values})
    plot(df, x="j", y="i", color="value",
         Scale.color_gradient,
         Geom.rectbin, Stat.identity)
end


