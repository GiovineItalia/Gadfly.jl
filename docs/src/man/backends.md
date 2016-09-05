```@meta
Author = "Daniel C. Jones, Tamas Nagy"
```

# Backends

**Gadfly** supports writing to the SVG and SVGJS backends out of the box. However,
the PNG, PDF, and PS backends require Julia's bindings to
[Cairo](https://github.com/JuliaGraphics/Cairo.jl). It can be installed with

```julia
Pkg.add("Cairo")
```

Additionally, complex layouts involving text are more accurate when
Pango and Fontconfig are installed.

## Changing the backend

Drawing to different backends is easy

```julia
# define a plot
myplot = plot(..)

# draw on every available backend
draw(SVG("myplot.svg", 4inch, 3inch), myplot)
draw(SVGJS("myplot.svg", 4inch, 3inch), myplot)
draw(PNG("myplot.png", 4inch, 3inch), myplot)
draw(PDF("myplot.pdf", 4inch, 3inch), myplot)
draw(PS("myplot.ps", 4inch, 3inch), myplot)
draw(PGF("myplot.tex", 4inch, 3inch), myplot)
```

!!! note

    The `SVGJS` backend writes SVG with embedded javascript. There are a couple
    subtleties with using the output from this backend.

    Drawing to the backend works like any other

    ```julia
    draw(SVGJS("mammals.js.svg", 6inch, 6inch), p)
    ```

    If included with an `<img>` tag, it will display as a static SVG image

    ```html
    <img src="mammals.js.svg"/>
    ```

    For the interactive javascript features to be enabled, the output either needs
    to be included inline in the HTML page, or included with an object tag

    ```html
    <object data="mammals.js.svg" type="image/svg+xml"></object>
    ```

    A `div` element must be placed, and the `draw` function defined in mammals.js
    must be passed the id of this element, so it knows where in the document to
    place the plot.

## IJulia

The [IJulia](https://github.com/JuliaLang/IJulia.jl) project adds Julia support
to [Jupyter](https://jupyter.org/). This includes a browser based notebook
that can inline graphics and plots. Gadfly works out of the box with IJulia,
with or without drawing explicity to a backend.

Without a explicit call to `draw` (i.e. just calling `plot`), the D3 backend is used with
a default plot size. The default plot size can be changed with `set_default_plot_size`.

```julia
# E.g.
set_default_plot_size(12cm, 8cm)
```
