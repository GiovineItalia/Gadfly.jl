```@meta
Author = "Daniel C. Jones, Shashi Gowda"
```

# Themes

Many parameters controlling the appearance of plots can be overridden by
passing a `Theme` object to the `plot` function, or setting the `Theme` as the
current theme using `push_theme` or `with_theme`.

The constructor for `Theme` takes zero or more keyword arguments each of which
overrides the default value of the corresponding field.  See [`Theme`](@ref) for
a full list of keywords.

```@example 1
using Gadfly, RDatasets
set_default_plot_size(14cm, 8cm)  # hide
mammals = dataset("MASS", "mammals")
plot(mammals, x=:Body, y=:Brain, label=:Mammal,
     Geom.point, Geom.label, Scale.x_log10, Scale.y_log10,
     Theme(discrete_highlight_color=x->"red", default_color="white"))
```


## The Theme stack

Gadfly maintains a stack of themes and applies theme values from the topmost theme in the stack. This can be useful when you want to set a theme for multiple plots and then switch back to a previous theme.

`push_theme(t::Theme)` and `pop_theme()` will push and pop from this stack
respectively. You can also use `with_theme(f, t::Theme)` to temporarily set a
theme as the current theme and call function `f`, which can be defined
elsewhere, anonymously, or as a do-block.

For example, here is how to choose a different font:

```@example 1
latex_fonts = Theme(major_label_font="CMU Serif", major_label_font_size=16pt,
                    minor_label_font="CMU Serif", minor_label_font_size=14pt,
                    key_title_font="CMU Serif", key_title_font_size=12pt,
                    key_label_font="CMU Serif", key_label_font_size=10pt)
Gadfly.push_theme(latex_fonts)
gasoline = dataset("Ecdat", "Gasoline")
p = plot(gasoline, x=:Year, y=:LGasPCar, color=:Country, Geom.point, Geom.line)
# can plot more plots here...
Gadfly.pop_theme()
p # hide
```

The same effect can be achieved using `with_theme`:

```julia
Gadfly.with_theme(latex_fonts) do
    gasoline = dataset("Ecdat", "Gasoline")
    plot(gasoline, x=:Year, y=:LGasPCar, color=:Country, Geom.point, Geom.line)
end
```


## `style`

You can use `style` to override the fields of the current theme. Much like
`Theme`'s constructor, `style` inputs keyword arguments, returns a `Theme`,
and can be used with `push_theme`, `with_theme`, and `plot`.

```@example 1
Gadfly.push_theme(style(line_width=1mm))
p1 = plot([sin,cos], 0, 2pi)
p2 = plot([sin,cos], 0, 2pi, style(line_width=2mm, line_style=[:dash]))
fig = hstack(p1,p2)
Gadfly.pop_theme()
fig # hide
```


## Named themes

To register a theme by name, you can extend `Gadfly.get_theme(::Val{:theme_name})` to return a Theme object.

```@example 1
Gadfly.get_theme(::Val{:orange}) = Theme(default_color="orange")

Gadfly.with_theme(:orange) do
    plot(dataset("datasets", "iris"), x=:SepalWidth, Geom.bar)
end
```

Gadfly comes built in with two named themes: `:default` and `:dark`.

```@example 1
Gadfly.with_theme(:dark) do
    plot(dataset("datasets", "iris"), x=:SepalLength, y=:SepalWidth, color=:Species)
end
```

You can also set a theme to use by default by setting the `GADFLY_THEME`
environment variable before loading Gadfly.
