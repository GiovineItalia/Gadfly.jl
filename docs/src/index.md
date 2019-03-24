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

The latest release of Gadfly can be installed from the Julia REPL prompt with

```julia
julia> ]add Gadfly
```

The closing square bracket switches to the package manager interface and the `add`
commands installs Gadfly and any missing dependencies.  To return to the Julia
REPL hit the `delete` key.

From there, the simplest of plots can be rendered to your default internet
browser with

```julia
julia> using Gadfly
julia> plot(y=[1,2,3])
```

Now that you have it installed, check out the [Tutorial](@ref) for a tour of
basic plotting and the various manual pages for more advanced usages.


## Compilation

Julia is just-in-time (JIT) compiled, which means that the first time you run a
block of code it will be slow.

One strategy for dealing with the tens of seconds it can take to display your
first plot is to rarely close your REPL session.
[Revise.jl](https://github.com/timholy/Revise.jl) is useful in this case as it
establishes a mechanism which automatically reloads code after it has been
modified, thereby reducing the need to restart.

Alternatively, one can avoid the first-time-to-plot penalty altogther by
ahead-of-time (AOT) compiling Gadfly into the Julia system image using
[PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl).

```julia
julia> ]dev PackageCompiler
julia> using PackageCompiler
julia> compile_package("Gadfly", force=false)
```

At the end of the resulting copius output will be the command to launch this
custom version of julia:  something like `julia -J
$HOME/.julia/dev/PackageCompiler/sysimg/sys.dylib`.  Make it convenient by
putting an alias in your .bashrc: `alias julia-gadfly="julia -J ..."`.

Note that multiple packages can be built into a new system image at the same
time by adding additional arguments: `compile_package("Gadfly",
"MyOtherFavoritePackage", ...)`.  Conversely, you don't have to precompile
everything you need though, as `]add ...` still works.

Now that `using Gadfly` takes just a split second, there's no reason not to
do so automatically in your `$HOME/.julia/config/startup.jl` file.

A few caveats:

- PackageCompiler is a work in progress, and the most recent tagged release
sometimes (currently as of this writing) does not work.  Hence the `dev`
instead of `add` command to install.

- Updating to the latest versions of compiled packages requires a recompile.
`]up`ing only works for those that haven't been built into the system image.

- Plots won't be automatically displayed in your default browswer unless you
tweak `Base.Multimedia.displays` to return the GadflyDisplay to the last entry.
To do so, add `atreplinit(x->pushdisplay(Gadfly.GadflyDisplay()))` to
your `startup.jl`, or `pushdisplay` manually.

- JULIA_PROJECT is entirely disregarded--  you'll have to manually `]activate
...`.  see https://github.com/JuliaLang/PackageCompiler.jl/issues/228.
