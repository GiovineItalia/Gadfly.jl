```@meta
Author = "Daniel C. Jones"
```

# Scales

Scales, similarly to [Statistics](@ref), apply a transformation to the original
data, typically mapping one aesthetic to the same aesthetic, while retaining
the original value. For example, the Scale.x_log10 aesthetic maps the
 `x` aesthetic back to the `x` aesthetic after applying a log10 transformation,
but keeps track of the original value so that data points are properly
identified.

## Available Scales

```@contents
Pages = map(file -> joinpath("scales", file), readdir("scales"))
Depth = 1
```
