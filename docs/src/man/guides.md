# Guides

Very similar to [Geometries](@ref) are guides, which draw graphics supporting the
actual visualization, such as axis ticks and labels and color keys. The major
distinction is that geometries always draw within the rectangular plot frame,
while guides have some special layout considerations.

## Available Guides

```@contents
Pages = map(file -> joinpath("..", "lib", "guides", file), readdir(joinpath("..", "lib", "guides")))
Depth = 1
```
