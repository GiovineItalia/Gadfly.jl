<div align="center"> <img
src="https://cdn.rawgit.com/GiovineItalia/Gadfly.jl/master/docs/src/assets/logo.svg"
alt="Gadfly Logo" width="210"></img> </div>

| **Documentation** | **Build Status** | **Help** |
|:---:|:---:|:---:|
| [![][docs-dev-img]][docs-dev-url] [![][docs-stable-img]][docs-stable-url] | [![][travis-img]][travis-url] [![][codecov-img]][codecov-url] | [![][slack-img]][slack-url] [![][gitter-img]][gitter-url] |

**Gadfly** is a plotting and data visualization system written in
[Julia](http://julialang.org/).

It's influenced heavily by Leland Wilkinson's book [The Grammar of Graphics][gog-book]
and Hadley Wickham's refinement of that grammar in [ggplot2](http://ggplot2.org/).

If you use **Gadfly** in a publication please consider citing it: [![DOI][citation-img]][citation-url]

## Package features

- Renders publication quality graphics to SVG, PNG, Postscript, and PDF
- Intuitive and consistent plotting interface
- Works with [IJulia](https://github.com/JuliaLang/IJulia.jl) out of the box
- Tight integration with [DataFrames.jl](https://github.com/JuliaStats/DataFrames.jl)
- Interactivity like panning, zooming, toggling powered by [Snap.svg](http://snapsvg.io/)
- Supports a large number of common plot types

## Installation & Quickstart

**Gadfly** is registered on `METADATA.jl` and so can be installed using `Pkg.add`.

```julia
Pkg.add("Gadfly")
```

To create a plot it's as simple as:

```julia
using Gadfly
plot(y=[1,2,3])
```

## Gallery

<div align="center"> <img
src="https://cdn.rawgit.com/GiovineItalia/Gadfly.jl/master/docs/src/assets/gallery.png"
alt="Gadfly Gallery" width="1024"></img> </div>

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of the documentation.**
- [**DEVEL**][docs-dev-url] &mdash; *in-development version of the documentation.*

## Contributing and Questions

This is a new and fairly complex piece of software. [Filing an
issue](https://github.com/GiovineItalia/Gadfly.jl/issues/new) to report a
bug, counterintuitive behavior, or even requesting a feature is extremely
valuable in helping us prioritize what to work on, so don't hesitate.

If you have a question then you can ask for help in the plotting team of the
[Julia Slack channel][slack-url] or the [Gitter chat room][gitter-url].

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: http://gadflyjl.org/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: http://gadflyjl.org/stable

[travis-img]: http://img.shields.io/travis/GiovineItalia/Gadfly.jl.svg
[travis-url]: https://travis-ci.org/GiovineItalia/Gadfly.jl
[codecov-img]: https://codecov.io/gh/GiovineItalia/Gadfly.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/GiovineItalia/Gadfly.jl

[citation-img]: https://zenodo.org/badge/DOI/10.5281/zenodo.1284282.svg
[citation-url]: https://doi.org/10.5281/zenodo.1284282

[gog-book]: http://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html

[slack-img]: https://img.shields.io/badge/chat-on%20slack-yellow.svg
[slack-url]: https://julialang.slack.com

[gitter-img]: https://badges.gitter.im/dcjnones/Gadfly.jl.svg
[gitter-url]: https://gitter.im/dcjones/Gadfly.jl
