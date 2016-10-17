```@meta
Author = "Daniel C. Jones"
```

# Geometries

Geometries are responsible for actually doing the drawing. A geometry takes
as input one or more aesthetics, and used data bound to these aesthetics to
draw things. For instance, the [Geom.point](@ref) geometry draws points using
the `x` and `y` aesthetics, while the [Geom.line](@ref) geometry draws lines
with those same two aesthetics.

## Available Geometries

```@contents
Pages = map(file -> joinpath("geoms", file), readdir("geoms"))
Depth = 1
```
