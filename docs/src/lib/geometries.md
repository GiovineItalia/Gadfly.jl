```@meta
Author = "Daniel C. Jones"
```

# [Geometries](@id lib_geom)

Geometries are responsible for actually doing the drawing. A geometry takes
as input one or more aesthetics, and use data bound to these aesthetics to
draw things. For instance, the [`Geom.point`](@ref) geometry draws points using
the `x` and `y` aesthetics, while the [`Geom.line`](@ref) geometry draws lines
with those same two aesthetics.

Core geometries:

```@index
Modules = [Geom]
Order = [:type]
```

Derived geometries build on core geometries by automatically applying a default
statistic:

```@index
Modules = [Geom]
Order = [:function]
```

```@autodocs
Modules = [Geom]
```
