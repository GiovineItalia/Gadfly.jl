# Executable Documentation with Gadfly

This is an executable document.

It's plain (pandoc flavored) markdown, but it can run through Gadfly.weave to
execute each code block and insert the output of the block into the document.
Unlike other executable documentation systems, there is absolutely no new syntax
introduced. Input is markdown, leveraging extensions introduced in pandoc to
annotate code blocks with necessary information.

There is a convenient script to run Gadfly.weave in the bin directory. To
execute this document, just run (assuming you are in the examples directory):

```{.shell execute="false"}
../bin/gadfly executable_documentation.md > executable_documentation.html
```

This depends on pandoc being installed in your path, naturally. The resulting
html file lacks stylesheets by default, so it will look pretty bland, but you'll
get the idea.

Here are a few examples:

### Simple Output

By default, anything printed to standard output will be collected and inserted
verbatim after the code block.

```{.julia}
for i in 1:10
    println(i)
end
```

### Images

If the code block is tagged with `.img`, anything output to standard out will
assumed to be an image and inserted as such. Let's draw something with Compose.

```{.julia .img}
draw(SVG(2inch, 2inch),
     compose(canvas(), rectangle(), fill("plum"), stroke(nothing)))
```

More interesting, you can plot things directly into the document.

```{.julia .img}
require("Distributions")
using Distributions

require("DataFrames")
using DataFrames

draw(SVG(4inch, 4inch),
     plot(DataFrame({"x" => rand(Normal(), 1000)}), {:x => "x"}, Geom.bar))
```

Even functions.

```{.julia .img}
draw(SVG(6inch, 3inch), plot([sin, cos], 1, 25))
```

### Grahviz

Graphviz works too:

```{.graphviz .img}
digraph {
    a -> b
    b -> c
    c -> d
    d -> b
    d -> a
    e -> c
    c -> a
}
```

### Latex

Also some preliminary support for latex.

```{.latex .img}
\documentclass{article}
\pagestyle{empty}
\begin{document}
$$\sum_{k=1}^{\infty} \frac{1}{2^k}$$
\end{document}
```

