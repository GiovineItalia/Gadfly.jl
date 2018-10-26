```@meta
Author = "Daniel C. Jones, Tamas Nagy"
```

# Backends

Gadfly supports creating SVG images out of the box through the native Julian
renderer in [Compose.jl](https://github.com/GiovineItalia/Compose.jl).  The
PNG, PDF, PS, and PGF formats, however, require Julia's bindings to
[cairo](https://www.cairographics.org/) and
[fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/), which can
be installed with

```julia
Pkg.add("Cairo")
Pkg.add("Fontconfig")
```


## Rendering to a file

In addition to the `draw` interface presented in the [Tutorial](@ref Tutorial):

```julia
p = plot(...)
draw(SVG("foo.svg", 6inch, 4inch), p)
```

one can more succintly use Julia's function chaining syntax:

```julia
p |> SVG("foo.svg", 6inch, 4inch)
```

If you plan on drawing many figures of the same size, consider
setting it as the default:

```julia
set_default_plot_size(6inch, 4inch)
p1 |> SVG("foo1.svg")
p2 |> SVG("foo2.svg")
p3 |> SVG("foo3.svg")
```


## Choosing a backend

Drawing to different backends is easy.  Simply swap `SVG` for one
of `SVGJS`, `PNG`, `PDF`, `PS`, or `PGF`:

```julia
# e.g.
p |> PDF("foo.pdf")
```


## Interactive SVGs

The `SVGJS` backend writes SVG with embedded javascript. There are a couple
subtleties with using the output from this backend.

Drawing to the backend works like any other

```julia
draw(SVGJS("foo.svg", 6inch, 6inch), p)
```

If included with an `<img>` tag, the output will display as a static SVG image
though.

```html
<img src="foo.svg"/>
```

For the [interactive](@ref Interactivity) javascript features to be enabled, it
either needs to be included inline in the HTML page, or included with an object
tag.

```html
<object data="foo.svg" type="image/svg+xml"></object>
```

For the latter, a `div` element must be placed, and the `draw` function
must be passed the id of this element, so it knows where in the
document to place the plot.


## IJulia

The [IJulia](https://github.com/JuliaLang/IJulia.jl) project adds Julia support
to [Jupyter](https://jupyter.org/). This includes a browser based notebook
that can inline graphics and plots. Gadfly works out of the box with IJulia,
with or without drawing explicity to a backend.

Without an explicit call to `draw` (i.e. just calling `plot` without a trailing
semicolon), the SVGJS backend is used with the default plot size, which can be
changed as described above.
