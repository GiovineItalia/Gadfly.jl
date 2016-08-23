# Gadfly.jl

Gadfly is a system for plotting and visualization written in [Julia](https://julialang.org).
It is based largely on Hadley Wickhams's [ggplot2](http://ggplot2.org/) for R and Leland Wilkinson's book
[The Grammar of Graphics](http://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html).
It was [Daniel C. Jones'](https://github.com/dcjones) brainchild and is now maintained by
the community.

## Package features

- Renders publication quality graphics to SVG, PNG, Postscript, and PDF
- Intuitive and consistent plotting interface
- Works with [IJulia](https://github.com/JuliaLang/IJulia.jl) out of the box
- Tight integration with [DataFrames.jl](https://github.com/JuliaStats/DataFrames.jl)
- Interactivity like panning, zooming, toggling powered by [Snap.svg](http://snapsvg.io/)
- Supports a large number of common plot types

## Quickstart

The latest release of **Gadfly** can be installed from the Julia REPL prompt with

```julia
julia> Pkg.add("Gadfly")
```

This installs the package and any missing dependencies. **Gadfly** can be
loaded with

```julia
julia> using Gadfly
```

See the [Plotting](@ref) for more information on plot invocations.

## Manual outline

```@contents
Pages = [
    "man/plotting.md",
    "man/layers.md",
    "man/backends.md",
    "man/themes.md"
]
Depth = 1
```
