

# Particularly useful or beautiful grammar of graphics invocations.


# A convenience plot function for quickly plotting functions or expressions.
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
function plot(fs::Array, a, b, elements::ElementOrFunction...; mapping...)
    # Catch a common misuse of this function
    if isa(b, ElementOrFunction)
        error(
        """
        Invalid plot usage:
            plot(xs, ys, ...) should be plot(x=xs, y=ys, ...)
        """)
    end

    if isempty(elements)
        elements = ElementOrFunction[]
    elseif isa(elements, Tuple)
        elements = ElementOrFunction[elements...]
    end

    element_types = Set(map(typeof, elements))

    if !in(Guide.xlabel, element_types)
        push!(elements, Guide.xlabel("x"))
    end

    if !in(Guide.ylabel, element_types)
        push!(elements, Guide.ylabel("f(x)"))
    end

    if b < a
        push!(elements, Coord.cartesian(xflip=true))
    end

    mappingdict = @compat Dict{Symbol, Any}(:y => fs, :xmin => [a], :xmax => [b])
    for (k, v) in mapping
        mappingdict[k] = v
    end

    plot(Stat.func, Geom.line, elements...; mappingdict...)
end


# Plot a single function.
function plot(f::Function, a, b, elements::ElementOrFunction...; mapping...)
    plot(Function[f], a, b, elements...; mapping...)
end


# Plot a single function using a contour plot
function plot(f::Function, xmin, xmax, ymin, ymax,
              elements::ElementOrFunction...; mapping...)
    default_elements = ElementOrFunction[]
    element_types = Set(map(typeof, elements))

    if !in(Guide.xlabel, element_types)
        push!(default_elements, Guide.xlabel("x"))
    end

    if !in(Guide.ylabel, element_types)
        push!(default_elements, Guide.ylabel("y"))
    end

    if !in(Guide.ColorKey, element_types) && !in(Guide.ManualColorKey, element_types)
        push!(default_elements, Guide.colorkey("f(x,y)"))
    end

    push!(default_elements, Coord.cartesian(xflip=xmin > xmax, yflip=ymin > ymax))

    plot(layer(f, xmin, xmax, ymin, ymax,
               elements...; mapping...), default_elements...)
end


function layer(f::Function, xmin, xmax, ymin, ymax,
               elements::ElementOrFunction...; mapping...)
    if isempty(elements)
        elements = ElementOrFunction[]
    elseif isa(elements, Tuple)
        elements = ElementOrFunction[elements...]
    end


    mappingdict = @compat Dict{Symbol, Any}(:z    => f, :xmin => [xmin], :xmax => [xmax],
                                            :ymin => [ymin], :ymax => [ymax])
    for (k, v) in mapping
        mappingdict[k] = v
    end

    layer(Geom.contour, elements...; mappingdict...)
end



# Create a layer from a list of functions or expressions.
function layer(fs::Array, a, b, elements::ElementOrFunction...)
    layer(y=fs, xmin=[a], xmax=[b], Stat.func, Geom.line, elements...)
end


# Create a layer from a single function.
function layer(f::Function, a, b, elements::ElementOrFunction...)
    layer([f], a, b, elements...)
end


# Simple heatmap plots of matrices.
#
# Args:
#   M: A matrix.
#
# Returns:
#   A plot object.
#
function spy(M::AbstractMatrix, elements::ElementOrFunction...; mapping...)
    is, js, values = findnz(M)
    df = DataFrame(i=is, j=js, value=values)
    plot(df, x="j", y="i", color="value",
         Coord.cartesian(yflip=true),
         Scale.color_continuous,
         Scale.x_continuous,
         Scale.y_continuous,
         Geom.rectbin,
         Stat.identity,
         elements...;
         mapping...)
end


