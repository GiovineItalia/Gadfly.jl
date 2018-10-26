```@meta
Author = "Tamas Nagy"
```

# Gadfly.jl

Gadfly is a system for plotting and visualization written in
[Julia](https://julialang.org). It is based largely on Hadley Wickhams's
[ggplot2](http://ggplot2.org/) for R and Leland Wilkinson's book [The
Grammar of
Graphics](http://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html).
It was [Daniel C. Jones'](https://github.com/dcjones) brainchild and is
now maintained by the community.
Please consider [citing
it](https://zenodo.org/record/1284282) if you use it in your work.

## Package features

- Renders publication quality graphics to SVG, PNG, Postscript, and PDF
- Intuitive and consistent plotting interface
- Works with [Jupyter](http://jupyter.org/) notebooks via [IJulia](https://github.com/JuliaLang/IJulia.jl) out of the box
- Tight integration with [DataFrames.jl](https://github.com/JuliaStats/DataFrames.jl)
- Interactivity like panning, zooming, toggling powered by [Snap.svg](http://snapsvg.io/)
- Supports a large number of common plot types

## Installation

The latest release of **Gadfly** can be installed from the Julia REPL prompt with

```julia
julia> Pkg.add("Gadfly")
```

This installs the package and any missing dependencies.  From there, the
simplest of plots can be rendered to your default internet browser with

```julia
julia> using Gadfly
julia> plot(y=[1,2,3])
```

Now that you have it installed, check out the [Tutorial](@ref) for a tour of
basic plotting and the various manual pages for more advanced usages.
