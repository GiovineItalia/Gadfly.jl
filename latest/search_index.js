var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": "Author = \"Tamas Nagy\""
},

{
    "location": "index.html#Gadfly.jl-1",
    "page": "Home",
    "title": "Gadfly.jl",
    "category": "section",
    "text": "Gadfly is a system for plotting and visualization written in Julia. It is based largely on Hadley Wickhams\'s ggplot2 for R and Leland Wilkinson\'s book The Grammar of Graphics. It was Daniel C. Jones\' brainchild and is now maintained by the community."
},

{
    "location": "index.html#Package-features-1",
    "page": "Home",
    "title": "Package features",
    "category": "section",
    "text": "Renders publication quality graphics to SVG, PNG, Postscript, and PDF\nIntuitive and consistent plotting interface\nWorks with IJulia out of the box\nTight integration with DataFrames.jl\nInteractivity like panning, zooming, toggling powered by Snap.svg\nSupports a large number of common plot types"
},

{
    "location": "index.html#Quickstart-1",
    "page": "Home",
    "title": "Quickstart",
    "category": "section",
    "text": "The latest release of Gadfly can be installed from the Julia REPL prompt withjulia> Pkg.add(\"Gadfly\")This installs the package and any missing dependencies. Gadfly can be loaded withjulia> using GadflyNow that you have it loaded, check out the Tutorial for a tour of basic plotting and the various manual pages for more advanced usages."
},

{
    "location": "index.html#Credits-1",
    "page": "Home",
    "title": "Credits",
    "category": "section",
    "text": "Gadfly is predominantly the work of Daniel C. Jones who initiated the project and built out most of the infrastructure.  It is now maintained by a community of volunteers.  Please consider citing it if you use it in your work."
},

{
    "location": "tutorial.html#",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "page",
    "text": "Author = \"Tamas Nagy, Daniel C. Jones, Simon Leblanc\""
},

{
    "location": "tutorial.html#Tutorial-1",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "section",
    "text": "Gadfly is an implementation of a \"grammar of graphics\" style statistical graphics system for Julia. This tutorial will outline general usage patterns and will give you a feel for the overall system.To begin, we need some data. Gadfly works best when the data is supplied in a DataFrame. In this tutorial, we\'ll pick and choose some examples from the RDatasets package.Let us use Fisher\'s iris dataset as a starting point.using Gadfly\nusing RDatasets\n\niris = dataset(\"datasets\", \"iris\")\nnothing # hideThe plot function in Gadfly is of the form:plot(data::DataFrame, mapping::Dict, elements::Element...)The first argument is the data to be plotted, the second is a dictionary mapping \"aesthetics\" to columns in the data frame, and this is followed by some number of elements, which are the nouns and verbs, so to speak, that form the grammar.Let\'s get to it.p = plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point);\nnothing # hideThis produces a Plot object. It can be saved to a file by drawing to one or more backends using draw.img = SVG(\"iris_plot.svg\", 6inch, 4inch)\ndraw(img, p)Now we have the following charming little SVG image.p # hideIf you are working at the REPL, a quicker way to see the image is to omit the semi-colon trailing plot.  This automatically renders the image to your default multimedia display, typically an internet browser.  No need to capture the output argument in this case.plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point)Alternatively one can manually call display on a Plot object.  This workflow is necessary when display would not otherwise be called automatically.function get_to_it(d)\n  ppoint = plot(d, x=:SepalLength, y=:SepalWidth, Geom.point)\n  pline = plot(d, x=:SepalLength, y=:SepalWidth, Geom.line)\n  ppoint, pline\nend\nps = get_to_it(iris)\nmap(display, ps)For the rest of the demonstrations, we\'ll simply omit the trailing semi-colon for brevity.In this plot we\'ve mapped the x aesthetic to the SepalLength column and the y aesthetic to the SepalWidth. The last argument, Geom.point, is a geometry element which takes bound aesthetics and renders delightful figures. Adding other geometries produces layers, which may or may not result in a coherent plot.plot(iris, x=:SepalLength, y=:SepalWidth,\n         Geom.point, Geom.line)This is the grammar of graphics equivalent of \"colorless green ideas sleep furiously\". It is valid grammar, but not particularly meaningful."
},

{
    "location": "tutorial.html#Color-1",
    "page": "Tutorial",
    "title": "Color",
    "category": "section",
    "text": "Let\'s do add something meaningful by mapping the color aesthetic.plot(iris, x=:SepalLength, y=:SepalWidth, color=:Species,\n         Geom.point)Ah, a scientific discovery: Setosa has short but wide sepals!Color scales in Gadfly by default are produced from perceptually uniform colorspaces (LUV/LCHuv or LAB/LCHab), though it supports RGB, HSV, HLS, XYZ, and converts arbitrarily between these. Of course, CSS/X11 named colors work too: \"old lace\", anyone?"
},

{
    "location": "tutorial.html#Scale-transforms-1",
    "page": "Tutorial",
    "title": "Scale transforms",
    "category": "section",
    "text": "Scale transforms also work as expected. Let\'s look at some data where this is useful.mammals = dataset(\"MASS\", \"mammals\")\nplot(mammals, x=:Body, y=:Brain, label=:Mammal, Geom.point, Geom.label)This is no good, the large animals are ruining things for us. Putting both axis on a log-scale clears things up.plot(mammals, x=:Body, y=:Brain, label=:Mammal,\n         Geom.point, Geom.label, Scale.x_log10, Scale.y_log10)"
},

{
    "location": "tutorial.html#Discrete-scales-1",
    "page": "Tutorial",
    "title": "Discrete scales",
    "category": "section",
    "text": "Since all continuous analysis is just degenerate discrete analysis, let\'s take a crack at the latter using some fuel efficiency data.gasoline = dataset(\"Ecdat\", \"Gasoline\")\n\nplot(gasoline, x=:Year, y=:LGasPCar, color=:Country,\n         Geom.point, Geom.line)We could have added Scale.x_discrete explicitly, but this is detected and the right default is chosen. This is the case with most of the elements in the grammar: we\'ve omitted Scale.x_continuous and Scale.y_continuous in the previous plots, as well as Coord.cartesian, and guide elements such as Guide.xticks, Guide.xlabel, and so on. As much as possible the system tries to fill in the gaps with reasonable defaults."
},

{
    "location": "tutorial.html#Rendering-1",
    "page": "Tutorial",
    "title": "Rendering",
    "category": "section",
    "text": "Gadfly uses a custom graphics library called Compose, which is an attempt at a more elegant, purely functional take on the R grid package. It allows mixing of absolute and relative units and complex coordinate transforms. The primary backend is a native SVG generator (almost native: it uses pango to precompute text extents), though there is also a Cairo backend. See Backends for more details.Building graphics declaratively let\'s you do some fun things. Like stick two plots together:fig1a = plot(iris, x=\"SepalLength\", y=\"SepalWidth\", Geom.point)\nfig1b = plot(iris, x=\"SepalWidth\", Geom.bar)\nfig1 = hstack(fig1a, fig1b)Ultimately this will make more complex visualizations easier to build. For example, facets, plots within plots, and so on. See Layers and Stacks for more details."
},

{
    "location": "tutorial.html#Interactivity-1",
    "page": "Tutorial",
    "title": "Interactivity",
    "category": "section",
    "text": "One advantage of generating our own SVG is that the files are much more compact than those produced by Cairo, by virtue of having a higher level API. Another advantage is that we can annotate our SVG output and embed Javascript code to provide some level of dynamism.Though not a replacement for full-fledged custom interactive visualizations of the sort produced by d3, this sort of mild interactivity can improve a lot of standard plots. The fuel efficiency plot is made more clear by toggling off some of the countries, for example.  To do so, simply click or shift-click in the colored squares in the table of keys to the right.One can also zoom in and out by pressing the shift key while either scrolling the mouse wheel or clicking and dragging a box.  Should your mouse not work, try the plus, minus, I, and O, keys.  Panning is similarly easy: click and drag without depressing the shift key, or use the arrow keys.  For Vim enthusiasts, the H, J, K, and L keys pan as expected.  To reset the plot to it\'s initial state, double click it or hit R.Lastly, press C to toggle on and off a numerical display of the cursor coordinates."
},

{
    "location": "man/plotting.html#",
    "page": "Plotting",
    "title": "Plotting",
    "category": "page",
    "text": "Author = \"Daniel C. Jones\""
},

{
    "location": "man/plotting.html#Plotting-1",
    "page": "Plotting",
    "title": "Plotting",
    "category": "section",
    "text": "Most interaction with Gadfly is through the plot function. Plots are described by binding data to aesthetics, and specifying a number of plot elements including Scales, Coordinates, Guides, and Geometries.  Aesthetics are a set of special named variables that are mapped to plot geometry. How this mapping occurs is defined by the plot elements.This \"grammar of graphics\" approach tries to avoid arcane incantations and special cases, instead approaching the problem as if one were drawing a wiring diagram: data is connected to aesthetics, which act as input leads, and elements, each self-contained with well-defined inputs and outputs, are connected and combined to produce the desired result."
},

{
    "location": "man/plotting.html#Plotting-arrays-1",
    "page": "Plotting",
    "title": "Plotting arrays",
    "category": "section",
    "text": "If no plot elements are defined, point geometry is added by default. The point geometry takes as input the x and y aesthetics. So all that\'s needed to draw a scatterplot is to bind x and y.using Gadfly\nsrand(12345)# E.g.\np = # hide\nplot(x=rand(10), y=rand(10))Multiple elements can use the same aesthetics to produce different output. Here the point and line geometries act on the same data and their results are layered.# E.g.\nplot(x=rand(10), y=rand(10), Geom.point, Geom.line)More complex plots can be produced by combining elements.# E.g.\nplot(x=1:10, y=2.^rand(10),\n     Scale.y_sqrt, Geom.point, Geom.smooth,\n     Guide.xlabel(\"Stimulus\"), Guide.ylabel(\"Response\"), Guide.title(\"Dog Training\"))To generate an image file from a plot, use the draw function. Gadfly supports a number of drawing Backends."
},

{
    "location": "man/plotting.html#Plotting-data-frames-1",
    "page": "Plotting",
    "title": "Plotting data frames",
    "category": "section",
    "text": "The DataFrames package provides a powerful means of representing and manipulating tabular data. They can be used directly in Gadfly to make more complex plots simpler and easier to generate.In this form of plot, a data frame is passed to as the first argument, and columns of the data frame are bound to aesthetics by name or index.# Signature for the plot applied to a data frames.\nplot(data::AbstractDataFrame, elements::Element...; mapping...)The RDatasets package collects example data sets from R packages. We\'ll use that here to generate some example plots on realistic data sets. An example data set is loaded into a data frame using the dataset function.using RDatasets# E.g.\nplot(dataset(\"datasets\", \"iris\"), x=\"SepalLength\", y=\"SepalWidth\", Geom.point)# E.g.\nplot(dataset(\"car\", \"SLID\"), x=\"Wages\", color=\"Language\", Geom.histogram)Along with less typing, using data frames to generate plots allows the axis and guide labels to be set automatically."
},

{
    "location": "man/plotting.html#Functions-and-Expressions-1",
    "page": "Plotting",
    "title": "Functions and Expressions",
    "category": "section",
    "text": "Along with the standard plot function, Gadfly has some special forms to make plotting functions and expressions more convenient.plot(f::Function, a, b, elements::Element...)\n\nplot(fs::Array, a, b, elements::Element...)Some special forms of plot exist for quickly generating 2d plots of functions.# E.g.\nplot([sin, cos], 0, 25)"
},

{
    "location": "man/plotting.html#Plotting-wide-formatted-data-1",
    "page": "Plotting",
    "title": "Plotting wide-formatted data",
    "category": "section",
    "text": "Gadfly is designed to plot data is so-called \"long form\", in which data that is of the same type, or measuring the same quantity, are stored in a single column, and any factors or groups are specified by additional columns. This is how data is typically stored in a database.Sometimes data tables are organized by grouping values of the same type into multiple columns, with a column name used to distinguish the grouping. We refer to this as \"wide form\" data.To illustrate the difference consider some historical London birth rate data.births = RDatasets.dataset(\"HistData\", \"Arbuthnot\")[[:Year, :Males, :Females]]Row Year Males Females\n1 1629 5218 4683\n2 1630 4858 4457\n3 1631 4422 4102\n4 1632 4994 4590\n5 1633 5158 4839\n6 1634 5035 4820This table is wide form because \"Males\" and \"Females\" are two columns both measuring number of births. Wide form data can always be transformed to long form, e.g. with the stack function in DataFrames, but this can be inconvenient, especially if the data is not already in a DataFrame.stack(births, [:Males, :Females])Row variable value Year\n1 Males 5218 1629\n2 Males 4858 1630\n3 Males 4422 1631\n... ... ... ...\n162 Females 7623 1708\n163 Females 7380 1709\n164 Females 7288 1710The resulting table is long form with number of births in one columns, here with the default name given by stack: \"value\". Data in this form can be plotted very conveniently with Gadfly.births = RDatasets.dataset(\"HistData\", \"Arbuthnot\")[[:Year, :Males, :Females]] # hide\nplot(stack(births, [:Males, :Females]), x=:Year, y=:value, color=:variable,\n     Geom.line)In some cases, explicitly transforming the data can be burdensome. Gadfly lets you avoid this be referring to columns or groups of columns in a implicit long-form version of the data.plot(births, x=:Year, y=Col.value(:Males, :Females),\n     color=Col.index(:Males, :Females), Geom.line)Here Col.value produces the concatenated values from a set of columns, and Col.index refers to a vector labeling each value in that concatenation by the column it came from. Also useful is Row.index, which will give the row index of items in a concatenation.This syntax also lets us more conveniently plot data that is not in a DataFrame, such as matrices or arrays of arrays. Here we plot each column of a matrix as a separate line.X = randn(40, 20) * diagm(1:20)\nplot(X, x=Row.index, y=Col.value, color=Col.index, Geom.line)When given no arguments Row.index, Col.index, and Col.value assume all columns are being concatenated, but we could have equivalently used Col.index(1:20...), etc.Plotting arrays of vectors works in much the same way as matrices, but constituent vectors maybe be of varying lengths.X = [randn(rand(10:20)) for _ in 1:10]\nplot(X, x=Row.index, y=Col.value, color=Col.index, Geom.line)"
},

{
    "location": "man/layers.html#",
    "page": "Layers and Stacks",
    "title": "Layers and Stacks",
    "category": "page",
    "text": "Author = \"Daniel C. Jones\""
},

{
    "location": "man/layers.html#Layers-and-Stacks-1",
    "page": "Layers and Stacks",
    "title": "Layers and Stacks",
    "category": "section",
    "text": "Gadfly also supports more advanced plot composition techniques like layering and stacking."
},

{
    "location": "man/layers.html#Layers-1",
    "page": "Layers and Stacks",
    "title": "Layers",
    "category": "section",
    "text": "Draw multiple layers onto the same plot withusing Gadfly\nusing Compose\nsrand(123)\nset_default_plot_size(12cm, 8cm)plot(layer(x=rand(10), y=rand(10), Geom.point),\n     layer(x=rand(10), y=rand(10), Geom.line))Or if your data is in a DataFrame:plot(my_data, layer(x=\"some_column1\", y=\"some_column2\", Geom.point),\n              layer(x=\"some_column3\", y=\"some_column4\", Geom.line))You can also pass different data frames to each layer:layer(another_dataframe, x=\"col1\", y=\"col2\", Geom.point)Ordering of layers in the Z direction can be controlled with the order keyword. A higher order number will cause a layer to be drawn on top of any layers with a lower number. If not specified, default order for a layer is 0.# using stacks (see below)\nxs = rand(0:10, 100, 2)\np1 = plot(layer(x=xs[:, 1], color=[colorant\"orange\"], Geom.histogram),\n          layer(x=xs[:, 2], Geom.histogram), Guide.title(\"Default ordering\"))\np2 = plot(layer(x=xs[:, 1], color=[colorant\"orange\"], Geom.histogram, order=1),\n          layer(x=xs[:, 2], Geom.histogram, order=2),\n          Guide.title(\"Manual ordering\"))\nhstack(p1, p2)Guide attributes may be added to a multi-layer plots:plt=plot(layer(x=rand(10), y=rand(10), Geom.point),\n         layer(x=rand(10), y=rand(10), Geom.line),\n         Guide.xlabel(\"x label\"),\n         Guide.ylabel(\"y label\"),\n         Guide.title(\"Title\"))"
},

{
    "location": "man/layers.html#Stacks-1",
    "page": "Layers and Stacks",
    "title": "Stacks",
    "category": "section",
    "text": "Plots can also be stacked horizontally with hstack or vertically with vstack, and arranged into a rectangular array with gridstack.  This allows more customization in regards to tick marks, axis labeling, and other plot details than is available with Geom.subplot_grid.p1 = plot(x=[1,2,3], y=[4,5,6]);\np2 = plot(x=[1,2,3], y=[6,7,8]);\nhstack(p1,p2)set_default_plot_size(12cm, 10cm) # hide\np3 = plot(x=[5,7,8], y=[8,9,10]);\np4 = plot(x=[5,7,8], y=[10,11,12]);\n\n# these two are equivalent\nvstack(hstack(p1,p2),hstack(p3,p4));\ngridstack([p1 p2; p3 p4])You can use title to add a descriptive string to the top of a stackset_default_plot_size(12cm, 8cm) # hide\ntitle(hstack(p3,p4), \"My great data\")You can also leave panels empty in a stack by passing a Compose.context() objectset_default_plot_size(12cm, 10cm) # hide\n# empty panel\ngridstack(Union{Plot,Compose.Context}[p1 p2; p3 Compose.context()])"
},

{
    "location": "man/backends.html#",
    "page": "Backends",
    "title": "Backends",
    "category": "page",
    "text": "Author = \"Daniel C. Jones, Tamas Nagy\""
},

{
    "location": "man/backends.html#Backends-1",
    "page": "Backends",
    "title": "Backends",
    "category": "section",
    "text": "Gadfly supports writing to the SVG and SVGJS backends out of the box. However, the PNG, PDF, and PS backends require Julia\'s bindings to Cairo. It can be installed withPkg.add(\"Cairo\")Additionally, complex layouts involving text are more accurate when Pango and Fontconfig are installed."
},

{
    "location": "man/backends.html#Changing-the-backend-1",
    "page": "Backends",
    "title": "Changing the backend",
    "category": "section",
    "text": "Drawing to different backends is easy# define a plot\nmyplot = plot(..)\n\n# draw on every available backend\ndraw(SVG(\"myplot.svg\", 4inch, 3inch), myplot)\ndraw(SVGJS(\"myplot.svg\", 4inch, 3inch), myplot)\ndraw(PNG(\"myplot.png\", 4inch, 3inch), myplot)\ndraw(PDF(\"myplot.pdf\", 4inch, 3inch), myplot)\ndraw(PS(\"myplot.ps\", 4inch, 3inch), myplot)\ndraw(PGF(\"myplot.tex\", 4inch, 3inch), myplot)note: Note\nThe SVGJS backend writes SVG with embedded javascript. There are a couple subtleties with using the output from this backend.Drawing to the backend works like any otherdraw(SVGJS(\"mammals.js.svg\", 6inch, 6inch), p)If included with an <img> tag, it will display as a static SVG image<img src=\"mammals.js.svg\"/>For the interactive javascript features to be enabled, the output either needs to be included inline in the HTML page, or included with an object tag<object data=\"mammals.js.svg\" type=\"image/svg+xml\"></object>A div element must be placed, and the draw function defined in mammals.js must be passed the id of this element, so it knows where in the document to place the plot."
},

{
    "location": "man/backends.html#IJulia-1",
    "page": "Backends",
    "title": "IJulia",
    "category": "section",
    "text": "The IJulia project adds Julia support to Jupyter. This includes a browser based notebook that can inline graphics and plots. Gadfly works out of the box with IJulia, with or without drawing explicity to a backend.Without a explicit call to draw (i.e. just calling plot), the D3 backend is used with a default plot size. The default plot size can be changed with set_default_plot_size.# E.g.\nset_default_plot_size(12cm, 8cm)"
},

{
    "location": "man/themes.html#",
    "page": "Themes",
    "title": "Themes",
    "category": "page",
    "text": "Author = \"Daniel C. Jones, Shashi Gowda\""
},

{
    "location": "man/themes.html#Themes-1",
    "page": "Themes",
    "title": "Themes",
    "category": "section",
    "text": "Many parameters controlling the appearance of plots can be overridden by passing a Theme object to the plot function. Or setting the Theme as the current theme using push_theme (see also pop_theme and with_theme below).The constructor for Theme takes zero or more named arguments each of which overrides the default value of the field."
},

{
    "location": "man/themes.html#The-Theme-stack-1",
    "page": "Themes",
    "title": "The Theme stack",
    "category": "section",
    "text": "Gadfly maintains a stack of themes and applies theme values from the topmost theme in the stack. This can be useful when you want to set a theme for multiple plots and then switch back to a previous theme.push_theme(t::Theme) and pop_theme() will push and pop from this stack respectively. You can use with_theme(f, t::Theme) to set a theme as the current theme and call f()."
},

{
    "location": "man/themes.html#style-1",
    "page": "Themes",
    "title": "style",
    "category": "section",
    "text": "You can use style to override the fields on top of the current theme at the top of the stack. style(...) returns a Theme. So it can be used with push_theme and with_theme."
},

{
    "location": "man/themes.html#Parameters-1",
    "page": "Themes",
    "title": "Parameters",
    "category": "section",
    "text": "These parameters can either be used with Theme or styledefault_color: When the color aesthetic is not bound, geometry uses this color for drawing. (Color)\npoint_size: Size of points in the point, boxplot, and beeswarm geometries.  (Measure)\npoint_size_min: Minimum size of points in the point geometry.  (Measure)\npoint_size_max: Maximum size of points in the point geometry.  (Measure)\npoint_shapes: Shapes of points in the point geometry.  (Function in circle, square, diamond, cross, xcross, utriangle, dtriangle, star1, star2, hexagon, octagon, hline, vline)\nline_width: Width of lines in the line geometry. (Measure)\nline_style: Style of lines in the line geometry. (Symbol in :solid, :dash, :dot, :dashdot, :dashdotdot, or Vector of Measures)\npanel_fill: Background color used in the main plot panel. ( Color or Nothing)\npanel_opacity: Opacity of the plot background panel. (Float in [0.0, 1.0])\npanel_stroke: Border color of the main plot panel. (Color or Nothing)\nbackground_color: Background color for the entire plot. If nothing, no background. (Color or Nothing)\nplot_padding: Padding around the plot. The order of padding is: plot_padding=[left, right, top, bottom]. If a vector of length one is provided e.g.  [5mm] then that value is applied to all sides. Absolute or relative units can be used. (Vector{<:Measure})\ngrid_color: Color of grid lines. (Color or Nothing)\ngrid_color_focused: In the D3 backend, mousing over the plot makes the grid lines emphasised by transitioning to this color. (Color or Nothing)\ngrid_line_width: Width of grid lines. (Measure)\ngrid_line_style: Style of grid lines. (Symbol in :solid, :dash, :dot, :dashdot, :dashdotdot, or Vector of Measures)   \nminor_label_font: Font used for minor labels such as tick labels and entries in keys. (String)\nminor_label_font_size: Font size used for minor labels. (Measure)\nminor_label_color: Color used for minor labels. (Color)\nmajor_label_font: Font used for major labels such as guide titles and axis labels. (String)\nmajor_label_font_size: Font size used for major labels. (Measure)\nmajor_label_color: Color used for major labels. (Color)\npoint_label_font: Font used for labels in Geom.label. (String)\npoint_label_font_size: Font size used for labels. (Measure)\npoint_label_color: Color used for labels. (Color)\nkey_position: Where key should be placed relative to the plot panel. One of :left, :right, :top, :bottom, :inside or :none. Setting to :none disables the key. Setting to :inside places the key in the lower right quadrant of the plot. (Symbol)\nkey_title_font: Font used for titles of keys. (String)\nkey_title_font_size: Font size used for key titles. (Measure)\nkey_title_color: Color used for key titles. (Color)\nkey_label_font: Font used for key entry labels. (String)\nkey_label_font_size: Font size used for key entry labels. (Measure)\nkey_label_color: Color used for key entry labels. (Color)\nkey_max_columns: Maximum number of columns for key entry labels. (Int)\nkey_swatch_shape: General purpose, will eventually replace colorkey_swatch_shape (Function as in point_shapes)\nkey_swatch_color: General purpose, currently works for Guide.shapekey (Color)\nbar_spacing: Spacing between bars in Geom.bar. (Measure)\nboxplot_spacing: Spacing between boxplots in Geom.boxplot. (Measure)\nerrorbar_cap_length: Length of caps on error bars. (Measure)\nhighlight_width: Width of lines drawn around plot geometry like points, and boxplot rectangles. (Measure)\ndiscrete_highlight_color and continuous_highlight_color: Color used to outline plot geometry. This is a function that alters (e.g. darkens) the fill color of the geometry. (Function)\nlowlight_color: Color used to draw background geometry, such as Geom.ribbon. This is a function that alters the fill color of the geometry. (Function)\nlowlight_opacity: Opacity of background geometry such as Geom.ribbon. (Float64)\nmiddle_color: Color altering function used to draw the midline in boxplots. (Function)\nmiddle_width: Width of the middle line in boxplots. (Measure)\nguide_title_position: One of :left, :center, :right indicating the  placement of the title of color key guides. (Symbol)\ncolorkey_swatch_shape: The shape used in color swatches in the color key guide. Either :circle or :square  (Symbol)\nbar_highlight: Color used to stroke bars in bar plots. If a function is given, it\'s used to transform the fill color of the bars to obtain a stroke color. (Function, Color, or Nothing)\ndiscrete_color_scale: A DiscreteColorScale see Scale.color_discrete_hue\ncontinuous_color_scale: A ContinuousColorScale see Scale.color_continuous\nlabel_out_of_bounds_penalty: Used by Geom.label(position=:dynamic)\nlabel_placement_iterations: Used by Geom.label(position=:dynamic)\nlabel_visibility_flip_pr: Used by Geom.label(position=:dynamic)\nlabel_hidden_penalty: Used by Geom.label(position=:dynamic)\nlabel_padding: Used by Geom.label(position=:dynamic)"
},

{
    "location": "man/themes.html#Examples-1",
    "page": "Themes",
    "title": "Examples",
    "category": "section",
    "text": "using RDatasets\nusing Gadfly\nset_default_plot_size(12cm, 8cm)\nsrand(12345)\ndark_panel = Theme(\n    panel_fill=\"black\",\n    default_color=\"orange\"\n)\n\nplot(x=rand(10), y=rand(10), dark_panel)\nSetting the font to Computer Modern to create a LaTeX-like look, and choosing a font size:Gadfly.push_theme(dark_panel)\n\np = plot(x=rand(10), y=rand(10),\n     style(major_label_font=\"CMU Serif\",minor_label_font=\"CMU Serif\",\n           major_label_font_size=16pt,minor_label_font_size=14pt))\n\n# can plot more plots here...\n\nGadfly.pop_theme()\n\np # hideSame effect can be had with with_themeGadfly.with_theme(dark_panel) do\n\n  plot(x=rand(10), y=rand(10),\n       style(major_label_font=\"CMU Serif\",minor_label_font=\"CMU Serif\",\n             major_label_font_size=16pt,minor_label_font_size=14pt))\nend\nnothing # hideor\nGadfly.push_theme(dark_panel)\n\nGadfly.with_theme(\n       style(major_label_font=\"CMU Serif\",minor_label_font=\"CMU Serif\",\n             major_label_font_size=16pt,minor_label_font_size=14pt)) do\n\n  plot(x=rand(10), y=rand(10))\n\nend\n\nGadfly.pop_theme()\nnothing # hide"
},

{
    "location": "man/themes.html#Named-themes-1",
    "page": "Themes",
    "title": "Named themes",
    "category": "section",
    "text": "To register a theme by name, you can extend Gadfly.get_theme(::Val{:theme_name}) to return a Theme object.Gadfly.get_theme(::Val{:orange}) =\n    Theme(default_color=\"orange\")\n\nGadfly.with_theme(:orange) do\n  plot(x=[1:10;], y=rand(10), Geom.bar)\nendGadfly comes built in with 2 named themes: :default and :dark. You can also set a theme to use by default by setting the GADFLY_THEME environment variable before loading Gadfly."
},

{
    "location": "man/themes.html#The-Dark-theme-1",
    "page": "Themes",
    "title": "The Dark theme",
    "category": "section",
    "text": "This is one of the two themes the ship with Gadfly the other being :default. Here are a few plots that use the dark theme.Gadfly.push_theme(:dark)\nnothing # hideplot(dataset(\"datasets\", \"iris\"),\n    x=\"SepalLength\", y=\"SepalWidth\", color=\"Species\", Geom.point)using RDatasets\n\ngasoline = dataset(\"Ecdat\", \"Gasoline\")\n\nplot(gasoline, x=:Year, y=:LGasPCar, color=:Country,\n         Geom.point, Geom.line)using DataFrames\n\nxs = 0:0.1:20\n\ndf_cos = DataFrame(\n    x=xs,\n    y=cos.(xs),\n    ymin=cos.(xs) .- 0.5,\n    ymax=cos.(xs) .+ 0.5,\n    f=\"cos\"\n)\n\ndf_sin = DataFrame(\n    x=xs,\n    y=sin.(xs),\n    ymin=sin.(xs) .- 0.5,\n    ymax=sin.(xs) .+ 0.5,\n    f=\"sin\"\n)\n\ndf = vcat(df_cos, df_sin)\np = plot(df, x=:x, y=:y, ymin=:ymin, ymax=:ymax, color=:f, Geom.line, Geom.ribbon)using Distributions\n\nX = rand(MultivariateNormal([0.0, 0.0], [1.0 0.5; 0.5 1.0]), 10000);\nplot(x=X[1,:], y=X[2,:], Geom.hexbin(xbincount=100, ybincount=100))Gadfly.pop_theme()"
},

{
    "location": "gallery/geometries.html#",
    "page": "Geometries",
    "title": "Geometries",
    "category": "page",
    "text": ""
},

{
    "location": "gallery/geometries.html#Geometries-1",
    "page": "Geometries",
    "title": "Geometries",
    "category": "section",
    "text": ""
},

{
    "location": "gallery/geometries.html#[Geom.abline](@ref)-1",
    "page": "Geometries",
    "title": "Geom.abline",
    "category": "section",
    "text": "using Gadfly, RDatasets, Compose\nset_default_plot_size(14cm, 8cm)\nplot(dataset(\"ggplot2\", \"mpg\"),\n     x=\"Cty\", y=\"Hwy\", label=\"Model\", Geom.point, Geom.label,\n     intercept=[0], slope=[1], Geom.abline(color=\"red\", style=:dash),\n     Guide.annotation(compose(context(), text(6,4, \"y=x\", hleft, vtop), fill(\"red\"))))"
},

{
    "location": "gallery/geometries.html#[Geom.bar](@ref)-1",
    "page": "Geometries",
    "title": "Geom.bar",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(14cm, 8cm)\nplot(dataset(\"HistData\", \"ChestSizes\"), x=\"Chest\", y=\"Count\", Geom.bar)using Gadfly, RDatasets, DataFrames\nset_default_plot_size(21cm, 8cm)\n\nD = by(dataset(\"datasets\",\"HairEyeColor\"), [:Eye,:Sex], d->sum(d[:Freq]))\np1 = plot(D, color=\"Eye\", y=\"x1\", x=\"Sex\", Geom.bar(position=:dodge),\n          Guide.ylabel(\"Freq\"));\n\nrename!(D, :x1 => :Frequency)\npalette = [\"brown\",\"blue\",\"tan\",\"green\"]  # Is there a hazel color?\n\np2a = plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),\n           Scale.color_discrete_manual(palette...));\np2b = plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),\n           Scale.color_discrete_manual(palette[4:-1:1]..., order=[4,3,2,1]));\n\nhstack(p1, p2a, p2b)See Scale.color_discrete_manual for more information."
},

{
    "location": "gallery/geometries.html#[Geom.beeswarm](@ref)-1",
    "page": "Geometries",
    "title": "Geom.beeswarm",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(14cm, 8cm)\nplot(dataset(\"lattice\", \"singer\"), x=\"VoicePart\", y=\"Height\", Geom.beeswarm)"
},

{
    "location": "gallery/geometries.html#[Geom.boxplot](@ref)-1",
    "page": "Geometries",
    "title": "Geom.boxplot",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(14cm, 8cm)\nplot(dataset(\"lattice\", \"singer\"), x=\"VoicePart\", y=\"Height\", Geom.boxplot)"
},

{
    "location": "gallery/geometries.html#[Geom.contour](@ref)-1",
    "page": "Geometries",
    "title": "Geom.contour",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(14cm, 8cm)\nplot(z=(x,y) -> x*exp(-(x-round(Int, x))^2-y^2),\n     xmin=[-8], xmax=[8], ymin=[-2], ymax=[2], Geom.contour)using Gadfly, RDatasets\nset_default_plot_size(21cm, 16cm)\nvolcano = Matrix{Float64}(dataset(\"datasets\", \"volcano\"))\np1 = plot(z=volcano, Geom.contour)\np2 = plot(z=volcano, Geom.contour(levels=[110.0, 150.0, 180.0, 190.0]))\np3 = plot(z=volcano, x=collect(0.0:10:860.0), y=collect(0.0:10:600.0),\n          Geom.contour(levels=2))\nMv = volcano[1:4:end, 1:4:end]\nDv = vcat([DataFrame(x=[1:size(Mv,1);], y=j, z=Mv[:,j]) for j in 1:size(Mv,2)]...)\np4 = plot(Dv, x=:x, y=:y, z=:z, color=:z,\n          Coord.cartesian(xmin=1, xmax=22, ymin=1, ymax=16),\n          Geom.point, Geom.contour(levels=10),\n          style(line_width=0.5mm, point_size=0.2mm) )\ngridstack([p1 p2; p3 p4])"
},

{
    "location": "gallery/geometries.html#[Geom.density](@ref)-1",
    "page": "Geometries",
    "title": "Geom.density",
    "category": "section",
    "text": "using Gadfly, RDatasets, Distributions\nset_default_plot_size(21cm, 8cm)\np1 = plot(dataset(\"ggplot2\", \"diamonds\"), x=\"Price\", Geom.density)\np2 = plot(dataset(\"ggplot2\", \"diamonds\"), x=\"Price\", color=\"Cut\", Geom.density)\nhstack(p1,p2)using Gadfly, RDatasets, Distributions\nset_default_plot_size(14cm, 8cm)\ndist = MixtureModel(Normal, [(0.5, 0.2), (1, 0.1)])\nxs = rand(dist, 10^5)\nplot(layer(x=xs, Geom.density, Theme(default_color=\"orange\")), \n     layer(x=xs, Geom.density(bandwidth=0.0003), Theme(default_color=\"green\")),\n     layer(x=xs, Geom.density(bandwidth=0.25), Theme(default_color=\"purple\")),\n     Guide.manual_color_key(\"bandwidth\", [\"auto\", \"bw=0.0003\", \"bw=0.25\"],\n                            [\"orange\", \"green\", \"purple\"]))"
},

{
    "location": "gallery/geometries.html#[Geom.density2d](@ref)-1",
    "page": "Geometries",
    "title": "Geom.density2d",
    "category": "section",
    "text": "using Gadfly, Distributions\nset_default_plot_size(14cm, 8cm)\nplot(x=rand(Rayleigh(2),1000), y=rand(Rayleigh(2),1000),\n     Geom.density2d(levels = x->maximum(x)*0.5.^collect(1:2:8)), Geom.point,\n     Theme(key_position=:none),\n     Scale.color_continuous(colormap=x->colorant\"red\"))"
},

{
    "location": "gallery/geometries.html#[Geom.ellipse](@ref)-1",
    "page": "Geometries",
    "title": "Geom.ellipse",
    "category": "section",
    "text": "using RDatasets, Gadfly\nset_default_plot_size(21cm, 8cm)\nD = dataset(\"datasets\",\"faithful\")\nD[:g] = D[:Eruptions].>3.0\ncoord = Coord.cartesian(ymin=35, ymax=100)\npa = plot(D, coord,\n          x=:Eruptions, y=:Waiting, group=:g,\n          Geom.point, Geom.ellipse)\npb = plot(D, coord,\n          x=:Eruptions, y=:Waiting, color=:g,\n          Geom.point, Geom.ellipse,\n          layer(Geom.ellipse(levels=[0.99]), style(line_style=:dot)),\n          style(key_position=:none), Guide.ylabel(nothing))\nhstack(pa,pb)"
},

{
    "location": "gallery/geometries.html#[Geom.errorbar](@ref)-1",
    "page": "Geometries",
    "title": "Geom.errorbar",
    "category": "section",
    "text": "using Gadfly, RDatasets, Distributions\nset_default_plot_size(14cm, 8cm)\nsrand(1234)\nsds = [1, 1/2, 1/4, 1/8, 1/16, 1/32]\nn = 10\nys = [mean(rand(Normal(0, sd), n)) for sd in sds]\nymins = ys .- (1.96 * sds / sqrt(n))\nymaxs = ys .+ (1.96 * sds / sqrt(n))\nplot(x=1:length(sds), y=ys, ymin=ymins, ymax=ymaxs,\n     Geom.point, Geom.errorbar)"
},

{
    "location": "gallery/geometries.html#[Geom.hair](@ref)-1",
    "page": "Geometries",
    "title": "Geom.hair",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(21cm, 8cm)\nx= 1:10\ns = [-1,-1,1,1,-1,-1,1,1,-1,-1]\npa = plot(x=x, y=x.^2, Geom.hair, Geom.point)\npb = plot(x=s.*(x.^2), y=x, color=string.(s),\n          Geom.hair(orientation=:horizontal), Geom.point, Theme(key_position=:none))\nhstack(pa, pb)"
},

{
    "location": "gallery/geometries.html#[Geom.hexbin](@ref)-1",
    "page": "Geometries",
    "title": "Geom.hexbin",
    "category": "section",
    "text": "using Gadfly, Distributions\nset_default_plot_size(21cm, 8cm)\nX = rand(MultivariateNormal([0.0, 0.0], [1.0 0.5; 0.5 1.0]), 10000);\np1 = plot(x=X[1,:], y=X[2,:], Geom.hexbin)\np2 = plot(x=X[1,:], y=X[2,:], Geom.hexbin(xbincount=100, ybincount=100))\nhstack(p1,p2)"
},

{
    "location": "gallery/geometries.html#[Geom.histogram](@ref)-1",
    "page": "Geometries",
    "title": "Geom.histogram",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(21cm, 16cm)\np1 = plot(dataset(\"ggplot2\", \"diamonds\"), x=\"Price\", Geom.histogram)\np2 = plot(dataset(\"ggplot2\", \"diamonds\"), x=\"Price\", color=\"Cut\", Geom.histogram)\np3 = plot(dataset(\"ggplot2\", \"diamonds\"), x=\"Price\", color=\"Cut\",\n          Geom.histogram(bincount=30))\np4 = plot(dataset(\"ggplot2\", \"diamonds\"), x=\"Price\", color=\"Cut\",\n          Geom.histogram(bincount=30, density=true))\ngridstack([p1 p2; p3 p4])"
},

{
    "location": "gallery/geometries.html#[Geom.histogram2d](@ref)-1",
    "page": "Geometries",
    "title": "Geom.histogram2d",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(21cm, 8cm)\np1 = plot(dataset(\"car\", \"Womenlf\"), x=\"HIncome\", y=\"Region\", Geom.histogram2d)\np2 = plot(dataset(\"car\", \"UN\"), x=\"GDP\", y=\"InfantMortality\",\n          Scale.x_log10, Scale.y_log10, Geom.histogram2d)\np3 = plot(dataset(\"car\", \"UN\"), x=\"GDP\", y=\"InfantMortality\",\n          Scale.x_log10, Scale.y_log10, Geom.histogram2d(xbincount=30, ybincount=30))\nhstack(p1,p2,p3)"
},

{
    "location": "gallery/geometries.html#[Geom.hline](@ref),-[Geom.vline](@ref)-1",
    "page": "Geometries",
    "title": "Geom.hline, Geom.vline",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(21cm, 8cm)\np1 = plot(dataset(\"datasets\", \"iris\"), x=\"SepalLength\", y=\"SepalWidth\",\n          xintercept=[5.0, 7.0], Geom.point, Geom.vline(style=[:solid,[1mm,1mm]]))\np2 = plot(dataset(\"datasets\", \"iris\"), x=\"SepalLength\", y=\"SepalWidth\",\n          yintercept=[2.5, 4.0], Geom.point,\n          Geom.hline(color=[\"orange\",\"red\"], size=[2mm,3mm]))\nhstack(p1,p2)"
},

{
    "location": "gallery/geometries.html#[Geom.label](@ref)-1",
    "page": "Geometries",
    "title": "Geom.label",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(14cm, 8cm)\nplot(dataset(\"ggplot2\", \"mpg\"), x=\"Cty\", y=\"Hwy\", label=\"Model\",\n     Geom.point, Geom.label)using Gadfly, RDatasets\nset_default_plot_size(21cm, 8cm)\np1 = plot(dataset(\"MASS\", \"mammals\"), x=\"Body\", y=\"Brain\", label=1,\n     Scale.x_log10, Scale.y_log10, Geom.point, Geom.label)\np2 = plot(dataset(\"MASS\", \"mammals\"), x=\"Body\", y=\"Brain\", label=1,\n     Scale.x_log10, Scale.y_log10, Geom.label(position=:centered))\nhstack(p1,p2)"
},

{
    "location": "gallery/geometries.html#[Geom.line](@ref)-1",
    "page": "Geometries",
    "title": "Geom.line",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(21cm, 8cm)\np1 = plot(dataset(\"lattice\", \"melanoma\"), x=\"Year\", y=\"Incidence\", Geom.line)\np2 = plot(dataset(\"Zelig\", \"approval\"), x=\"Month\",  y=\"Approve\", color=\"Year\",\n          Geom.line)\nhstack(p1,p2)"
},

{
    "location": "gallery/geometries.html#[Geom.path](@ref)-1",
    "page": "Geometries",
    "title": "Geom.path",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(21cm, 8cm)\n\nn = 500\nsrand(1234)\nxjumps = rand(n)-.5\nyjumps = rand(n)-.5\np1 = plot(x=cumsum(xjumps),y=cumsum(yjumps),Geom.path)\n\nt = 0:0.2:8pi\np2 = plot(x=t.*cos(t), y=t.*sin(t), Geom.path)\n\nhstack(p1,p2)"
},

{
    "location": "gallery/geometries.html#[Geom.point](@ref)-1",
    "page": "Geometries",
    "title": "Geom.point",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(21cm, 12cm)\nD = dataset(\"datasets\", \"iris\")\np1 = plot(D, x=\"SepalLength\", y=\"SepalWidth\", Geom.point);\np2 = plot(D, x=\"SepalLength\", y=\"SepalWidth\", color=\"PetalLength\", Geom.point);\np3 = plot(D, x=\"SepalLength\", y=\"SepalWidth\", color=\"Species\", Geom.point);\np4 = plot(D, x=\"SepalLength\", y=\"SepalWidth\", color=\"Species\", shape=\"Species\",\n          Geom.point);\ngridstack([p1 p2; p3 p4])using Gadfly, RDatasets\nset_default_plot_size(14cm, 8cm)\nplot(dataset(\"lattice\", \"singer\"), x=\"VoicePart\", y=\"Height\", Geom.point)using Gadfly, Distributions\nset_default_plot_size(14cm, 8cm)\nrdata = rand(MvNormal([0,0.],[1 0;0 1.]),100)\nbdata = rand(MvNormal([1,0.],[1 0;0 1.]),100)\nplot(layer(x=rdata[1,:], y=rdata[2,:], color=[colorant\"red\"], Geom.point),\n     layer(x=bdata[1,:], y=bdata[2,:], color=[colorant\"blue\"], Geom.point))"
},

{
    "location": "gallery/geometries.html#[Geom.polygon](@ref)-1",
    "page": "Geometries",
    "title": "Geom.polygon",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(14cm, 8cm)\nplot(x=[0, 1, 1, 2, 2, 3, 3, 2, 2, 1, 1, 0, 4, 5, 5, 4],\n     y=[0, 0, 1, 1, 0, 0, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3],\n     group=[\"H\", \"H\", \"H\", \"H\", \"H\", \"H\", \"H\", \"H\",\n            \"H\", \"H\", \"H\", \"H\", \"I\", \"I\", \"I\", \"I\"],\n     Geom.polygon(preserve_order=true, fill=true))"
},

{
    "location": "gallery/geometries.html#[Geom.rect](@ref),-[Geom.rectbin](@ref)-1",
    "page": "Geometries",
    "title": "Geom.rect, Geom.rectbin",
    "category": "section",
    "text": "using Gadfly, Colors, DataFrames, RDatasets\nset_default_plot_size(21cm, 8cm)\ntheme1 = Theme(default_color=RGBA(0, 0.75, 1.0, 0.5))\nD = DataFrame(x=[0.5,1], y=[0.5,1], x1=[0,0.5], y1=[0,0.5], x2=[1,1.5], y2=[1,1.5])\npa = plot(D, x=:x, y=:y, Geom.rectbin, theme1)\npb = plot(D, xmin=:x1, ymin=:y1, xmax=:x2, ymax=:y2, Geom.rect, theme1)\nhstack(pa, pb)using Gadfly, DataFrames, RDatasets\nset_default_plot_size(14cm, 8cm)\nplot(dataset(\"Zelig\", \"macro\"), x=\"Year\", y=\"Country\", color=\"GDP\", Geom.rectbin)"
},

{
    "location": "gallery/geometries.html#[Geom.ribbon](@ref)-1",
    "page": "Geometries",
    "title": "Geom.ribbon",
    "category": "section",
    "text": "using Gadfly, DataFrames\nset_default_plot_size(14cm, 8cm)\nxs = 0:0.1:20\ndf_cos = DataFrame(x=xs, y=cos(xs), ymin=cos(xs).-0.5, ymax=cos(xs).+0.5, f=\"cos\")\ndf_sin = DataFrame(x=xs, y=sin(xs), ymin=sin(xs).-0.5, ymax=sin(xs).+0.5, f=\"sin\")\ndf = vcat(df_cos, df_sin)\nplot(df, x=:x, y=:y, ymin=:ymin, ymax=:ymax, color=:f, Geom.line, Geom.ribbon)"
},

{
    "location": "gallery/geometries.html#[Geom.smooth](@ref)-1",
    "page": "Geometries",
    "title": "Geom.smooth",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(21cm, 8cm)\nx_data = 0.0:0.1:2.0\ny_data = x_data.^2 + rand(length(x_data))\np1 = plot(x=x_data, y=y_data, Geom.point, Geom.smooth(method=:loess,smoothing=0.9))\np2 = plot(x=x_data, y=y_data, Geom.point, Geom.smooth(method=:loess,smoothing=0.2))\nhstack(p1,p2)"
},

{
    "location": "gallery/geometries.html#[Geom.step](@ref)-1",
    "page": "Geometries",
    "title": "Geom.step",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(14cm, 8cm)\nsrand(1234)\nplot(x=rand(25), y=rand(25), Geom.step)"
},

{
    "location": "gallery/geometries.html#[Geom.subplot_grid](@ref)-1",
    "page": "Geometries",
    "title": "Geom.subplot_grid",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(21cm, 8cm)\nplot(dataset(\"datasets\", \"OrchardSprays\"),\n     xgroup=\"Treatment\", x=\"ColPos\", y=\"RowPos\", color=\"Decrease\",\n     Geom.subplot_grid(Geom.point))using Gadfly, RDatasets\nset_default_plot_size(14cm, 25cm)\nplot(dataset(\"vcd\", \"Suicide\"), xgroup=\"Sex\", ygroup=\"Method\", x=\"Age\", y=\"Freq\",\n     Geom.subplot_grid(Geom.bar))using Gadfly, RDatasets, DataFrames\nset_default_plot_size(14cm, 8cm)\niris = dataset(\"datasets\", \"iris\")\nsp = unique(iris[:Species])\nDhl = DataFrame(yint=[3.0, 4.0, 2.5, 3.5, 2.5, 4.0], Species=repeat(sp, inner=[2]) )\n# Try this one too:\n# Dhl = DataFrame(yint=[3.0, 4.0, 2.5, 3.5], Species=repeat(sp[1:2], inner=[2]) )\nplot(iris, xgroup=:Species, x=:SepalLength, y=:SepalWidth,\n    Geom.subplot_grid(layer(Geom.point),\n                      layer(Dhl, xgroup=:Species, yintercept=:yint,\n                            Geom.hline(color=\"red\", style=:dot))))using Gadfly, RDatasets, DataFrames\nset_default_plot_size(14cm, 8cm)\niris = dataset(\"datasets\", \"iris\")\nsp = unique(iris[:Species])\nDhl = DataFrame(yint=[3.0, 4.0, 2.5, 3.5, 2.5, 4.0], Species=repeat(sp, inner=[2]) )\nplot(iris, xgroup=:Species,\n     Geom.subplot_grid(layer(x=:SepalLength, y=:SepalWidth, Geom.point),\n                       layer(Dhl, xgroup=:Species, yintercept=:yint,\n                             Geom.hline(color=\"red\", style=:dot))),\n     Guide.xlabel(\"Xlabel\"), Guide.ylabel(\"Ylabel\"))using Gadfly, RDatasets, DataFrames\nset_default_plot_size(14cm, 12cm)\nwidedf = DataFrame(x = collect(1:10), var1 = collect(1:10), var2 = collect(1:10).^2)\nlongdf = stack(widedf, [:var1, :var2])\np1 = plot(longdf, ygroup=\"variable\", x=\"x\", y=\"value\", Geom.subplot_grid(Geom.point))\np2 = plot(longdf, ygroup=\"variable\", x=\"x\", y=\"value\", Geom.subplot_grid(Geom.point,\n          free_y_axis=true))\nhstack(p1,p2)"
},

{
    "location": "gallery/geometries.html#[Geom.vector](@ref)-1",
    "page": "Geometries",
    "title": "Geom.vector",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(14cm, 14cm)\n\nseals = RDatasets.dataset(\"ggplot2\",\"seals\")\nseals[:Latb] = seals[:Lat] + seals[:DeltaLat]\nseals[:Longb] = seals[:Long] + seals[:DeltaLong]\nseals[:Angle] = atan2.(seals[:DeltaLat], seals[:DeltaLong])\n\ncoord = Coord.cartesian(xmin=-175.0, xmax=-119, ymin=29, ymax=50)\n# Geom.vector also needs scales for both axes:\nxsc  = Scale.x_continuous(minvalue=-175.0, maxvalue=-119)\nysc  = Scale.y_continuous(minvalue=29, maxvalue=50)\ncolsc = Scale.color_continuous(minvalue=-3, maxvalue=3)\n\nlayer1 = layer(seals, x=:Long, y=:Lat, xend=:Longb, yend=:Latb, color=:Angle,\n               Geom.vector)\n\nplot(layer1, xsc, ysc, colsc, coord)"
},

{
    "location": "gallery/geometries.html#[Geom.vectorfield](@ref)-1",
    "page": "Geometries",
    "title": "Geom.vectorfield",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(21cm, 8cm)\n\ncoord = Coord.cartesian(xmin=-2, xmax=2, ymin=-2, ymax=2)\np1 = plot(coord, z=(x,y)->x*exp(-(x^2+y^2)), \n          xmin=[-2], xmax=[2], ymin=[-2], ymax=[2], \n# or:     x=-2:0.25:2.0, y=-2:0.25:2.0,     \n          Geom.vectorfield(scale=0.4, samples=17), Geom.contour(levels=6),\n          Scale.x_continuous(minvalue=-2.0, maxvalue=2.0),\n          Scale.y_continuous(minvalue=-2.0, maxvalue=2.0),\n          Guide.xlabel(\"x\"), Guide.ylabel(\"y\"), Guide.colorkey(title=\"z\"))\n\nvolcano = Matrix{Float64}(dataset(\"datasets\", \"volcano\"))\nvolc = volcano[1:4:end, 1:4:end] \ncoord = Coord.cartesian(xmin=1, xmax=22, ymin=1, ymax=16)\np2 = plot(coord, z=volc, x=1.0:22, y=1.0:16,\n          Geom.vectorfield(scale=0.05), Geom.contour(levels=7),\n          Scale.x_continuous(minvalue=1.0, maxvalue=22.0),\n          Scale.y_continuous(minvalue=1.0, maxvalue=16.0),\n          Guide.xlabel(\"x\"), Guide.ylabel(\"y\"),\n          Theme(key_position=:none))\n\nhstack(p1,p2)"
},

{
    "location": "gallery/geometries.html#[Geom.violin](@ref)-1",
    "page": "Geometries",
    "title": "Geom.violin",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(14cm, 8cm)\nDsing = dataset(\"lattice\",\"singer\")\nDsing[:Voice] = [x[1:5] for x in Dsing[:VoicePart]]\nplot(Dsing, x=:VoicePart, y=:Height, color=:Voice, Geom.violin)"
},

{
    "location": "gallery/guides.html#",
    "page": "Guides",
    "title": "Guides",
    "category": "page",
    "text": ""
},

{
    "location": "gallery/guides.html#Guides-1",
    "page": "Guides",
    "title": "Guides",
    "category": "section",
    "text": ""
},

{
    "location": "gallery/guides.html#[Guide.annotation](@ref)-1",
    "page": "Guides",
    "title": "Guide.annotation",
    "category": "section",
    "text": "using Gadfly, Compose\nset_default_plot_size(14cm, 8cm)\nplot(sin, 0, 2pi, Guide.annotation(compose(context(),\n     Shape.circle([pi/2, 3*pi/2], [1.0, -1.0], [2mm]),\n     fill(nothing), stroke(\"orange\"))))"
},

{
    "location": "gallery/guides.html#[Guide.colorkey](@ref)-1",
    "page": "Guides",
    "title": "Guide.colorkey",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(14cm, 8cm)\nDsleep = dataset(\"ggplot2\", \"msleep\")[[:Vore,:BrainWt,:BodyWt,:SleepTotal]]\nDataFrames.dropmissing!(Dsleep)\nDsleep[:SleepTime] = Dsleep[:SleepTotal] .> 8\nplot(Dsleep, x=:BodyWt, y=:BrainWt, Geom.point, color=:SleepTime, \n     Guide.colorkey(title=\"Sleep\", labels=[\">8\",\"≤8\"]),\n     Scale.x_log10, Scale.y_log10 )using Gadfly, Compose, RDatasets\nset_default_plot_size(21cm, 8cm)\niris = dataset(\"datasets\",\"iris\")\npa = plot(iris, x=:SepalLength, y=:PetalLength, color=:Species, Geom.point,\n          Theme(key_position=:inside) )\npb = plot(iris, x=:SepalLength, y=:PetalLength, color=:Species, Geom.point, \n          Guide.colorkey(title=\"Iris\", pos=[0.05w,-0.28h]) )\nhstack(pa, pb)"
},

{
    "location": "gallery/guides.html#[Guide.manual_color_key](@ref)-1",
    "page": "Guides",
    "title": "Guide.manual_color_key",
    "category": "section",
    "text": "using Gadfly, DataFrames\nset_default_plot_size(14cm, 8cm)\npoints = DataFrame(index=rand(0:10,30), val=rand(1:10,30))\nline = DataFrame(val=rand(1:10,11), index = collect(0:10))\npointLayer = layer(points, x=\"index\", y=\"val\", Geom.point,Theme(default_color=\"green\"))\nlineLayer = layer(line, x=\"index\", y=\"val\", Geom.line)\nplot(pointLayer, lineLayer,\n     Guide.manual_color_key(\"Legend\", [\"Points\", \"Line\"], [\"green\", \"deepskyblue\"]))"
},

{
    "location": "gallery/guides.html#[Guide.shapekey](@ref)-1",
    "page": "Guides",
    "title": "Guide.shapekey",
    "category": "section",
    "text": "using Compose, Gadfly, RDatasets\nset_default_plot_size(16cm, 8cm)\nDsleep = dataset(\"ggplot2\", \"msleep\")\nDsleep = dropmissing!(Dsleep[[:Vore, :Name,:BrainWt,:BodyWt, :SleepTotal]])\nDsleep[:SleepTime] = Dsleep[:SleepTotal] .> 8\nplot(Dsleep, x=:BodyWt, y=:BrainWt, Geom.point, color=:Vore, shape=:SleepTime,\n    Guide.colorkey(pos=[0.05w, -0.25h]),\n    Guide.shapekey(title=\"Sleep (hrs)\", labels=[\">8\",\"≤8\"], pos=[0.18w,-0.315h]),\n    Scale.x_log10, Scale.y_log10,\n    Theme(point_size=2mm, key_swatch_color=\"slategrey\", \n            point_shapes=[Shape.utriangle, Shape.dtriangle]) )"
},

{
    "location": "gallery/guides.html#[Guide.title](@ref)-1",
    "page": "Guides",
    "title": "Guide.title",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(14cm, 8cm)\nplot(dataset(\"ggplot2\", \"diamonds\"), x=\"Price\", Geom.histogram,\n     Guide.title(\"Diamond Price Distribution\"))"
},

{
    "location": "gallery/guides.html#[Guide.xlabel](@ref),-[Guide.ylabel](@ref)-1",
    "page": "Guides",
    "title": "Guide.xlabel, Guide.ylabel",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(21cm, 8cm)\np1 = plot(cos, 0, 2π, Guide.xlabel(\"Angle\"));\np2 = plot(cos, 0, 2π, Guide.xlabel(\"Angle\", orientation=:vertical));\np3 = plot(cos, 0, 2π, Guide.xlabel(nothing));\nhstack(p1,p2,p3)"
},

{
    "location": "gallery/guides.html#[Guide.xrug](@ref),-[Guide.yrug](@ref)-1",
    "page": "Guides",
    "title": "Guide.xrug, Guide.yrug",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(14cm, 8cm)\nplot(x=rand(20), y=rand(20), Guide.xrug)"
},

{
    "location": "gallery/guides.html#[Guide.xticks](@ref),-[Guide.yticks](@ref)-1",
    "page": "Guides",
    "title": "Guide.xticks, Guide.yticks",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(21cm, 8cm)\nticks = [0.1, 0.3, 0.5]\np1 = plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks))\np2 = plot(x=rand(10), y=rand(10), Geom.line, Guide.xticks(ticks=ticks, label=false))\np3 = plot(x=rand(10), y=rand(10), Geom.line,\n          Guide.xticks(ticks=ticks, orientation=:vertical))\nhstack(p1,p2,p3)using Gadfly\nset_default_plot_size(14cm, 8cm)\nplot(x=rand(1:10, 10), y=rand(1:10, 10), Geom.line, Guide.xticks(ticks=[1:9;]))"
},

{
    "location": "gallery/statistics.html#",
    "page": "Statistics",
    "title": "Statistics",
    "category": "page",
    "text": ""
},

{
    "location": "gallery/statistics.html#Statistics-1",
    "page": "Statistics",
    "title": "Statistics",
    "category": "section",
    "text": ""
},

{
    "location": "gallery/statistics.html#[Stat.binmean](@ref)-1",
    "page": "Statistics",
    "title": "Stat.binmean",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(21cm, 8cm)\np1 = plot(dataset(\"datasets\", \"iris\"), x=\"SepalLength\", y=\"SepalWidth\",\n          Geom.point)\np2 = plot(dataset(\"datasets\", \"iris\"), x=\"SepalLength\", y=\"SepalWidth\",\n          Stat.binmean, Geom.point)\nhstack(p1,p2)"
},

{
    "location": "gallery/statistics.html#[Stat.qq](@ref)-1",
    "page": "Statistics",
    "title": "Stat.qq",
    "category": "section",
    "text": "using Gadfly, Distributions\nset_default_plot_size(21cm, 8cm)\nsrand(1234)\np1 = plot(x=rand(Normal(), 100), y=rand(Normal(), 100), Stat.qq, Geom.point)\np2 = plot(x=rand(Normal(), 100), y=Normal(), Stat.qq, Geom.point)\nhstack(p1,p2)"
},

{
    "location": "gallery/statistics.html#[Stat.step](@ref)-1",
    "page": "Statistics",
    "title": "Stat.step",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(14cm, 8cm)\nsrand(1234)\nplot(x=rand(25), y=rand(25), Stat.step, Geom.line)"
},

{
    "location": "gallery/statistics.html#[Stat.x_jitter](@ref),-[Stat.y_jitter](@ref)-1",
    "page": "Statistics",
    "title": "Stat.x_jitter, Stat.y_jitter",
    "category": "section",
    "text": "using Gadfly, Distributions\nset_default_plot_size(14cm, 8cm)\nsrand(1234)\nplot(x=rand(1:4, 500), y=rand(500), Stat.x_jitter(range=0.5), Geom.point)"
},

{
    "location": "gallery/statistics.html#[Stat.xticks](@ref),-[Stat.yticks](@ref)-1",
    "page": "Statistics",
    "title": "Stat.xticks, Stat.yticks",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(14cm, 8cm)\nsrand(1234)\nplot(x=rand(10), y=rand(10), Stat.xticks(ticks=[0.0, 0.1, 0.9, 1.0]), Geom.point)"
},

{
    "location": "gallery/coordinates.html#",
    "page": "Coordinates",
    "title": "Coordinates",
    "category": "page",
    "text": ""
},

{
    "location": "gallery/coordinates.html#Coordinates-1",
    "page": "Coordinates",
    "title": "Coordinates",
    "category": "section",
    "text": ""
},

{
    "location": "gallery/coordinates.html#[Coord.cartesian](@ref)-1",
    "page": "Coordinates",
    "title": "Coord.cartesian",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(14cm, 8cm)\nplot(sin, 0, 20, Coord.cartesian(xmin=2π, xmax=4π, ymin=-2, ymax=2))"
},

{
    "location": "gallery/scales.html#",
    "page": "Scales",
    "title": "Scales",
    "category": "page",
    "text": ""
},

{
    "location": "gallery/scales.html#Scales-1",
    "page": "Scales",
    "title": "Scales",
    "category": "section",
    "text": ""
},

{
    "location": "gallery/scales.html#[Scale.color_continuous](@ref)-1",
    "page": "Scales",
    "title": "Scale.color_continuous",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(21cm, 8cm)\nxdata, ydata, cdata = rand(12), rand(12), rand(12)\np1 = plot(x=xdata, y=ydata, color=cdata)\np2 = plot(x=xdata, y=ydata, color=cdata,\n          Scale.color_continuous(minvalue=-1, maxvalue=1))\nhstack(p1,p2)using Gadfly, Colors\nset_default_plot_size(21cm, 8cm)\nx = repeat(collect(1:10)-0.5, inner=[10])\ny = repeat(collect(1:10)-0.5, outer=[10])\np1 = plot(x=x, y=y, color=x+y, Geom.rectbin,\n          Scale.color_continuous(colormap=p->RGB(0,p,0)))\np2 = plot(x=x, y=y, color=x+y, Geom.rectbin,\n          Scale.color_continuous(colormap=Scale.lab_gradient(\"green\", \"white\", \"red\")))\np3 = plot(x=x, y=y, color=x+y, Geom.rectbin,\n          Scale.color_continuous(colormap=p->RGB(0,p,0), minvalue=-20))\nhstack(p1,p2,p3)"
},

{
    "location": "gallery/scales.html#[Scale.color_discrete_hue](@ref)-1",
    "page": "Scales",
    "title": "Scale.color_discrete_hue",
    "category": "section",
    "text": "using Gadfly, Colors, RDatasets\nset_default_plot_size(14cm, 8cm)\nsrand(1234)\n\nfunction gen_colors(n)\n    cs = distinguishable_colors(n,\n                                [colorant\"#FE4365\", colorant\"#eca25c\"],\n                                lchoices = Float64[58, 45, 72.5, 90],\n                                transform = c -> deuteranopic(c, 0.1),\n                                cchoices = Float64[20,40],\n                                hchoices = [75,51,35,120,180,210,270,310])\n\n    convert(Vector{Color}, cs)\nend\n\niris = dataset(\"datasets\", \"iris\")\nplot(iris, x=:SepalLength, y=:SepalWidth, color=:Species,\n     Geom.point, Scale.color_discrete(gen_colors))using Gadfly, Colors, RDatasets\nset_default_plot_size(21cm, 8cm)\nsrand(1234)\nxdata, ydata = rand(12), rand(12)\np1 = plot(x=xdata, y=ydata, color=repeat([1,2,3], outer=[4]))\np2 = plot(x=xdata, y=ydata, color=repeat([1,2,3], outer=[4]), Scale.color_discrete)\nhstack(p1,p2)"
},

{
    "location": "gallery/scales.html#[Scale.color_discrete_manual](@ref)-1",
    "page": "Scales",
    "title": "Scale.color_discrete_manual",
    "category": "section",
    "text": "using Gadfly\nsrand(12345)\nset_default_plot_size(14cm, 8cm)\nplot(x=rand(12), y=rand(12), color=repeat([\"a\",\"b\",\"c\"], outer=[4]),\n     Scale.color_discrete_manual(\"red\",\"purple\",\"green\"))using Gadfly, RDatasets, DataFrames\nset_default_plot_size(14cm, 8cm)\nD = by(dataset(\"datasets\",\"HairEyeColor\"), [:Eye,:Sex], d->sum(d[:Freq]))\nrename!(D, :x1, :Frequency)\npalette = [\"brown\",\"blue\",\"tan\",\"green\"] # Is there a hazel color?\npa = plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),\n          Scale.color_discrete_manual(palette...))\npb = plot(D, x=:Sex, y=:Frequency, color=:Eye, Geom.bar(position=:stack),\n          Scale.color_discrete_manual(palette[4:-1:1]..., order=[4,3,2,1]))\nhstack(pa,pb)"
},

{
    "location": "gallery/scales.html#[Scale.color_none](@ref)-1",
    "page": "Scales",
    "title": "Scale.color_none",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(21cm, 8cm)\nxs = ys = 1:10.\nzs = Float64[x^2*log(y) for x in xs, y in ys]\np1 = plot(x=xs, y=ys, z=zs, Geom.contour);\np2 = plot(x=xs, y=ys, z=zs, Geom.contour, Scale.color_none);\nhstack(p1,p2)"
},

{
    "location": "gallery/scales.html#[Scale.x_continuous](@ref),-[Scale.y_continuous](@ref)-1",
    "page": "Scales",
    "title": "Scale.x_continuous, Scale.y_continuous",
    "category": "section",
    "text": "using Gadfly\nset_default_plot_size(21cm, 8cm)\nsrand(1234)\np1 = plot(x=rand(10), y=rand(10), Scale.x_continuous(minvalue=-10, maxvalue=10))\np2 = plot(x=rand(10), y=rand(10), Scale.x_continuous(format=:scientific))\np3 = plot(x=rand(10), y=rand(10), Scale.x_continuous(labels=x -> @sprintf(\"%0.4f\", x)))\nhstack(p1,p2,p3)using Gadfly\nset_default_plot_size(14cm, 8cm)\nsrand(1234)\nplot(x=rand(10), y=rand(10), Scale.x_log)"
},

{
    "location": "gallery/scales.html#[Scale.x_discrete](@ref),-[Scale.y_discrete](@ref)-1",
    "page": "Scales",
    "title": "Scale.x_discrete, Scale.y_discrete",
    "category": "section",
    "text": "using Gadfly, DataFrames\nset_default_plot_size(14cm, 8cm)\nsrand(1234)\n# Treat numerical x data as categories\np1 = plot(x=rand(1:3, 20), y=rand(20), Scale.x_discrete)\n# To perserve the order of the columns in the plot when plotting a DataFrame\ndf = DataFrame(v1 = randn(10), v2 = randn(10), v3 = randn(10))\np2 = plot(df, x=Col.index, y=Col.value, Scale.x_discrete(levels=names(df)))\nhstack(p1,p2)"
},

{
    "location": "gallery/shapes.html#",
    "page": "Shapes",
    "title": "Shapes",
    "category": "page",
    "text": ""
},

{
    "location": "gallery/shapes.html#Shapes-1",
    "page": "Shapes",
    "title": "Shapes",
    "category": "section",
    "text": ""
},

{
    "location": "gallery/shapes.html#[Shape.square](@ref)-1",
    "page": "Shapes",
    "title": "Shape.square",
    "category": "section",
    "text": "using Gadfly, RDatasets\nset_default_plot_size(14cm, 8cm)\nplot(dataset(\"HistData\",\"DrinksWages\"),\n     x=\"Wage\", y=\"Drinks\", shape=[Shape.square],\n     Geom.point, Scale.y_log10)"
},

{
    "location": "lib/gadfly.html#",
    "page": "Gadfly",
    "title": "Gadfly",
    "category": "page",
    "text": "Author = \"Ben J. Arthur\""
},

{
    "location": "lib/gadfly.html#Compose.draw-Tuple{Compose.Backend,Gadfly.Plot}",
    "page": "Gadfly",
    "title": "Compose.draw",
    "category": "method",
    "text": "draw(backend::Compose.Backend, p::Plot)\n\nA convenience version of Compose.draw without having to call render.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Compose.gridstack-Tuple{Array{Gadfly.Plot,2}}",
    "page": "Gadfly",
    "title": "Compose.gridstack",
    "category": "method",
    "text": "gridstack(ps::Matrix{Union{Plot,Context}})\n\nArrange plots into a rectangular array.  Use context() as a placeholder for an empty panel.  Heterogeneous matrices must be typed.  See also hstack and vstack.\n\nExamples\n\np1 = plot(x=[1,2], y=[3,4], Geom.line);\np2 = Compose.context();\ngridstack([p1 p1; p1 p1])\ngridstack(Union{Plot,Compose.Context}[p1 p2; p2 p1])\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Compose.hstack-Tuple{Vararg{Union{Compose.Context, Gadfly.Plot},N} where N}",
    "page": "Gadfly",
    "title": "Compose.hstack",
    "category": "method",
    "text": "hstack(ps::Union{Plot,Context}...)\nhstack(ps::Vector)\n\nArrange plots into a horizontal row.  Use context() as a placeholder for an empty panel.  Heterogeneous vectors must be typed.  See also vstack, gridstack, and Geom.subplot_grid.\n\nExamples\n\np1 = plot(x=[1,2], y=[3,4], Geom.line);\np2 = Compose.context();\nhstack(p1, p2)\nhstack(Union{Plot,Compose.Context}[p1, p2])\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Compose.vstack-Tuple{Vararg{Union{Compose.Context, Gadfly.Plot},N} where N}",
    "page": "Gadfly",
    "title": "Compose.vstack",
    "category": "method",
    "text": "vstack(ps::Union{Plot,Context}...)\nvstack(ps::Vector)\n\nArrange plots into a vertical column.  Use context() as a placeholder for an empty panel.  Heterogeneous vectors must be typed.  See also hstack, gridstack, and Geom.subplot_grid.\n\nExamples\n\np1 = plot(x=[1,2], y=[3,4], Geom.line);\np2 = Compose.context();\nvstack(p1, p2)\nvstack(Union{Plot,Compose.Context}[p1, p2])\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.layer-Tuple{Function,Number,Number,Number,Number,Vararg{Union{Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.layer",
    "category": "method",
    "text": "layer(f::Function, xmin::Number, xmax::Number, ymin::Number, ymax::Number,\n      elements::ElementOrFunction...; mapping...) -> [Layers]\n\nCreate a layer of the contours of the 2D function or expression in f. See Stat.func and Geom.contour.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.layer-Tuple{Function,Number,Number,Vararg{Union{Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.layer",
    "category": "method",
    "text": "layer(f::Function, lower::Number, upper::Number,\n      elements::ElementOrFunction...) -> [Layers]\n\nCreate a layer from the function or expression f, which takes a single argument or operates on a single variable, respectively, between the lower and upper bounds.  See Stat.func and Geom.line.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.layer-Tuple{Union{DataFrames.AbstractDataFrame, Void},Vararg{Union{Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.layer",
    "category": "method",
    "text": "layer(data_source::Union{AbstractDataFrame, Void}),\n      elements::ElementOrFunction...; mapping...) -> [Layers]\n\nCreate a layer element based on the data in data_source, to later input into plot.  elements can be Statistics, Geometries, and/or Themes (but not Scales, Coordinates, or Guides). mapping are aesthetics.\n\nExamples\n\nls=[]\nappend!(ls, layer(y=[1,2,3], Geom.line))\nappend!(ls, layer(y=[3,2,1], Geom.point))\nplot(ls..., Guide.title(\"layer example\"))\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.layer-Tuple{Vararg{Union{Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.layer",
    "category": "method",
    "text": "layer(elements::ElementOrFunction...; mapping...) =\n      layer(nothing, elements...; mapping...) -> [Layers]\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.layer-Union{Tuple{Array{T,1},Number,Number,Vararg{Union{Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}, Tuple{T}} where T<:Union{Function, Type}",
    "page": "Gadfly",
    "title": "Gadfly.layer",
    "category": "method",
    "text": "layer(fs::Vector{T}, lower::Number, upper::Number,\n      elements::ElementOrFunction...) where T <: Base.Callable -> [Layers]\n\nCreate a layer from a list of functions or expressions in fs.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.plot-Tuple{Function,Number,Number,Number,Number,Vararg{Union{Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.plot",
    "category": "method",
    "text": "plot(f::Function, xmin::Number, xmax::Number, ymin::Number, ymax::Number,\n     elements::ElementOrFunction...; mapping...)\n\nPlot the contours of the 2D function or expression in f. See Stat.func and Geom.contour.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.plot-Tuple{Function,Number,Number,Vararg{Union{Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.plot",
    "category": "method",
    "text": "plot(f::Function, lower::Number, upper::Number, elements::ElementOrFunction...;\n     mapping...)\n\nPlot the function or expression f, which takes a single argument or operates on a single variable, respectively, between the lower and upper bounds.  See Stat.func and Geom.line.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.plot-Tuple{Union{AbstractArray, DataFrames.AbstractDataFrame, Void},Dict,Vararg{Union{Array{Gadfly.Layer,1}, Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.plot",
    "category": "method",
    "text": "plot(data_source::Union{Void, AbstractMatrix, AbstractDataFrame},\n     mapping::Dict, elements::ElementOrFunctionOrLayers...) -> Plot\n\nThe old fashioned (pre-named arguments) version of plot.  This version takes an explicit mapping dictionary, mapping aesthetics symbols to expressions or columns in the data frame.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.plot-Tuple{Union{AbstractArray, DataFrames.AbstractDataFrame},Vararg{Union{Array{Gadfly.Layer,1}, Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.plot",
    "category": "method",
    "text": "plot(data_source::Union{AbstractMatrix, AbstractDataFrame},\n     elements::ElementOrFunctionOrLayers...; mapping...) -> Plot\n\nCreate a new plot by specifying a data_source, one or more plot elements (Scales, Statistics, Coordinates, Geometries, Guides, Themes, and/or Layers), and a mapping of aesthetics to columns or expressions of the data.\n\nExamples\n\nmy_data = DataFrame(time=1917:2018, price=1.02.^(0:101))\nplot(my_data, Geom.line, x=:time, y=:price)\n\n# or equivalently:\nplot(Geom.line, x=collect(1917:2018), y=1.02.^(0:101))\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.plot-Tuple{Vararg{Union{Array{Gadfly.Layer,1}, Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.plot",
    "category": "method",
    "text": "plot(elements::ElementOrFunctionOrLayers...; mapping...) -> Plot\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.plot-Union{Tuple{Array{T,1},Number,Number,Vararg{Union{Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}, Tuple{T}} where T<:Union{Function, Type}",
    "page": "Gadfly",
    "title": "Gadfly.plot",
    "category": "method",
    "text": "plot(fs::Vector{T}, lower::Number, upper::Number, elements::ElementOrFunction...;\n     mapping...) where T <: Base.Callable\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.render-Tuple{Gadfly.Plot}",
    "page": "Gadfly",
    "title": "Gadfly.render",
    "category": "method",
    "text": "render(plot::Plot) -> Context\n\nRender plot to a Compose context.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.set_default_plot_format-Tuple{Symbol}",
    "page": "Gadfly",
    "title": "Gadfly.set_default_plot_format",
    "category": "method",
    "text": "set_default_plot_format(fmt::Symbol)\n\nSets the default plot format.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.set_default_plot_size-Tuple{Union{Measures.Measure, Number},Union{Measures.Measure, Number}}",
    "page": "Gadfly",
    "title": "Gadfly.set_default_plot_size",
    "category": "method",
    "text": "set_default_plot_size(width::Compose.MeasureOrNumber,\n                      height::Compose.MeasureOrNumber)\n\nSets preferred canvas size when rendering a plot without an explicit call to draw.  Units can be inch, cm, mm, pt, or px.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.spy-Tuple{AbstractArray{T,2} where T,Vararg{Union{Function, Gadfly.Element, Gadfly.Theme, Type},N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.spy",
    "category": "method",
    "text": "spy(M::AbstractMatrix, elements::ElementOrFunction...; mapping...) -> Plot\n\nPlots a heatmap of M, with M[1,1] in the upper left.  NaN values are left blank, and an error is thrown if all elements of M are NaN.  See Geom.rectbin and Coord.cartesian(fixed=true)...).\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.style-Tuple{}",
    "page": "Gadfly",
    "title": "Gadfly.style",
    "category": "method",
    "text": "style(; kwargs...) -> Theme\n\nReturn a new Theme that is a copy of the current theme as modifed by the attributes in kwargs.  See Themes for available fields.\n\nExamples\n\nstyle(background_color=\"gray\")\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.title-Tuple{Compose.Context,String,Vararg{Compose.Property,N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.title",
    "category": "method",
    "text": "title(ctx::Context, str::String, props::Property...) -> Context\n\nAdd a title string to a group of plots, typically created with vstack, hstack, or gridstack.\n\nExamples\n\np1 = plot(x=[1,2], y=[3,4], Geom.line);\np2 = plot(x=[1,2], y=[4,3], Geom.line);\ntitle(hstack(p1,p2), \"my latest data\", Compose.fontsize(18pt), fill(colorant\"red\"))\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Base.Multimedia.display-Tuple{Base.REPL.REPLDisplay,Union{Compose.Context, Gadfly.Plot}}",
    "page": "Gadfly",
    "title": "Base.Multimedia.display",
    "category": "method",
    "text": "display(p::Plot)\n\nRender p to a multimedia display, typically an internet browser. This function is handy when rendering by plot has been suppressed with either trailing semi-colon or by calling it within a function.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.current_theme-Tuple{}",
    "page": "Gadfly",
    "title": "Gadfly.current_theme",
    "category": "method",
    "text": "current_theme()\n\nGet the Theme on top of the theme stack.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.get_theme-Tuple{Val{:dark}}",
    "page": "Gadfly",
    "title": "Gadfly.get_theme",
    "category": "method",
    "text": "get_theme(::Val{:dark})\n\nA light foreground on a dark background.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.get_theme-Tuple{Val{:default}}",
    "page": "Gadfly",
    "title": "Gadfly.get_theme",
    "category": "method",
    "text": "get_theme(::Val{:default})\n\nA dark foreground on a light background.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.get_theme-Union{Tuple{Val{name}}, Tuple{name}} where name",
    "page": "Gadfly",
    "title": "Gadfly.get_theme",
    "category": "method",
    "text": "get_theme()\n\nRegister a theme by name by adding methods to get_theme.\n\nExamples\n\nget_theme(::Val{:mytheme}) = Theme(...)\npush_theme(:mytheme)\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.lab_gradient-Tuple{Vararg{ColorTypes.Color,N} where N}",
    "page": "Gadfly",
    "title": "Gadfly.lab_gradient",
    "category": "method",
    "text": "function lab_gradient(cs::Color...)\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.lab_rainbow-NTuple{4,Any}",
    "page": "Gadfly",
    "title": "Gadfly.lab_rainbow",
    "category": "method",
    "text": "lab_rainbow(l, c, h0, n)\n\nGenerate n colors in the LCHab colorspace by using a fixed luminance l and chroma c, and varying the hue, starting at h0.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.lchabmix-NTuple{4,Any}",
    "page": "Gadfly",
    "title": "Gadfly.lchabmix",
    "category": "method",
    "text": "function lchabmix(c0_, c1_, r, power)\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.luv_rainbow-NTuple{4,Any}",
    "page": "Gadfly",
    "title": "Gadfly.luv_rainbow",
    "category": "method",
    "text": "luv_rainbow(l, c, h0, n)\n\nGenerate n colors in the LCHuv colorspace by using a fixed luminance l and chroma c, and varying the hue, starting at h0.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.pop_theme-Tuple{}",
    "page": "Gadfly",
    "title": "Gadfly.pop_theme",
    "category": "method",
    "text": "pop_theme() -> Theme\n\nReturn to using the previous theme by removing the top item on the theme stack. See also pop_theme and with_theme.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.push_theme-Tuple{Gadfly.Theme}",
    "page": "Gadfly",
    "title": "Gadfly.push_theme",
    "category": "method",
    "text": "push_theme(t::Theme)\n\nSet the current theme by placing t onto the top of the theme stack. See also pop_theme and with_theme.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.push_theme-Tuple{Symbol}",
    "page": "Gadfly",
    "title": "Gadfly.push_theme",
    "category": "method",
    "text": "push_theme(t::Symbol)\n\nPush a Theme by its name.  Available options are :default and :dark. See also get_theme.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.weighted_color_mean-Union{Tuple{AbstractArray{ColorTypes.Lab{T},1},AbstractArray{S,1}}, Tuple{S}, Tuple{T}} where T where S<:Number",
    "page": "Gadfly",
    "title": "Gadfly.weighted_color_mean",
    "category": "method",
    "text": "function weighted_color_mean(cs::AbstractArray{Lab{T},1},\n                             ws::AbstractArray{S,1}) where {S <: Number,T}\n\nReturn the mean of Lab colors cs as weighted by ws.\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly.with_theme-Tuple{Any,Any}",
    "page": "Gadfly",
    "title": "Gadfly.with_theme",
    "category": "method",
    "text": "with_theme(f, theme)\n\nCall function f with theme as the current Theme. theme can be a Theme object or a symbol.\n\nExamples\n\nwith_theme(style(background_color=colorant\"#888888\"))) do\n    plot(x=rand(10), y=rand(10))\nend\n\n\n\n"
},

{
    "location": "lib/gadfly.html#Gadfly-1",
    "page": "Gadfly",
    "title": "Gadfly",
    "category": "section",
    "text": "Modules = [Compose, Gadfly]Modules = [Gadfly]"
},

{
    "location": "lib/geometries.html#",
    "page": "Geometries",
    "title": "Geometries",
    "category": "page",
    "text": "Author = \"Daniel C. Jones\""
},

{
    "location": "lib/geometries.html#Gadfly.Geom.abline",
    "page": "Geometries",
    "title": "Gadfly.Geom.abline",
    "category": "type",
    "text": "Geom.abline[(; color=nothing, size=nothing, style=nothing)]\n\nFor each corresponding pair of elements in the intercept and slope aesthetics, draw the lines y = slope * x + intercept across the plot canvas. If unspecified, intercept defaults to [0] and slope to [1].\n\nThis geometry currently does not support non-linear Scale transformations.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.bar",
    "page": "Geometries",
    "title": "Gadfly.Geom.bar",
    "category": "type",
    "text": "Geom.bar[(; position=:stack, orientation=:vertical)]\n\nDraw bars of height y centered at positions x, or from xmin to xmax. If orientation is :horizontal switch x for y.  Optionally categorically groups bars using the color aesthetic.  If position is :stack they will be placed on top of each other;  if it is :dodge they will be placed side by side.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.beeswarm",
    "page": "Geometries",
    "title": "Gadfly.Geom.beeswarm",
    "category": "type",
    "text": "Geom.beeswarm[; (orientation=:vertical, padding=0.1mm)]\n\nPlot the x and y aesthetics, the former being categorical and the latter continuous, by shifting the x position of each point to ensure that there is at least padding gap between neighbors.  If orientation is :horizontal, switch x for y.  Points can optionally be colored using the color aesthetic.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.boxplot",
    "page": "Geometries",
    "title": "Gadfly.Geom.boxplot",
    "category": "type",
    "text": "Geom.boxplot[(; method=:tukey, suppress_outliers=false)]\n\nDraw box plots of the middle, lower_hinge, upper_hinge, lower_fence, upper_fence, and outliers aesthetics.  The categorical x aesthetic is optional.  If suppress_outliers is true, don\'t draw points indicating outliers.\n\nAlternatively, if the y aesthetic is specified instead, the middle, hinges, fences, and outliers aesthetics will be computed using Stat.boxplot.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.errorbar",
    "page": "Geometries",
    "title": "Gadfly.Geom.errorbar",
    "category": "type",
    "text": "Geom.errorbar\n\nDraw vertical error bars if the x, ymin, and ymax aesthetics are specified and/or horizontal error bars for y, xmin, and xmax. Optionally color them with color.\n\nSee also Geom.xerrorbar and Geom.yerrorbar.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.hexbin",
    "page": "Geometries",
    "title": "Gadfly.Geom.hexbin",
    "category": "type",
    "text": "Geom.hexbin[(; xbincount=200, ybincount=200)]\n\nBin the x and y aesthetics into tiled hexagons and color by count. xbincount and ybincount specify the number of bins.  This behavior relies on the default use of Stat.hexbin.\n\nAlternatively, draw hexagons of size xsize and ysize at positions x and y by passing Stat.identity to plot and manually binding the color aesthetic.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.hline",
    "page": "Geometries",
    "title": "Gadfly.Geom.hline",
    "category": "type",
    "text": "Geom.hline[(; color=nothing, size=nothing, style=nothing)]\n\nDraw horizontal lines across the plot canvas at each position in the yintercept aesthetic.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.label",
    "page": "Geometries",
    "title": "Gadfly.Geom.label",
    "category": "type",
    "text": "Geom.label[(; position=:dynamic, hide_overlaps=true)]\n\nPlace the text strings in the label aesthetic at the x and y coordinates on the plot frame.  Offset the text according to position, which can be :left, :right, :above, :below, :centered, or :dynamic.  The latter tries a variety of positions for each label to minimize the number that overlap.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.line",
    "page": "Geometries",
    "title": "Gadfly.Geom.line",
    "category": "type",
    "text": "Geom.line[(; preserve_order=false, order=2)]\n\nDraw a line connecting the x and y coordinates.  Optionally plot multiple lines according to the group or color aesthetics.  order controls whether the lines(s) are underneath or on top of other forms.\n\nSet preserve_order to :true to not sort the points according to their position along the x axis, or use the equivalent Geom.path alias.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.point",
    "page": "Geometries",
    "title": "Gadfly.Geom.point",
    "category": "type",
    "text": "Geom.point\n\nDraw scatter plots of the x and y aesthetics.\n\nOptional Aesthetics\n\ncolor: Categorical data will choose maximally distinguishable colors from the LCHab color space.  Continuous data will map onto LCHab as well.  Colors can also be specified explicitly for each data point with a vector of colors of length(x).  A vector of length one specifies the color to use for all points. Default is Theme.default_color.\nshape: Categorical data will cycle through Theme.point_shapes.  Shapes can also be specified explicitly for each data point with a vector of shapes of length(x).  A vector of length one specifies the shape to use for all points. Default is Theme.point_shapes[1].\nsize: Categorical data and vectors of Ints will interpolate between Theme.point_size_{min,max}.  A continuous vector of AbstractFloats or Measures of length(x) specifies the size of each data point explicitly.  A vector of length one specifies the size to use for all points.  Default is Theme.point_size.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.polygon",
    "page": "Geometries",
    "title": "Gadfly.Geom.polygon",
    "category": "type",
    "text": "Geom.polygon[(; order=0, fill=false, preserve_order=false)]\n\nDraw polygons with vertices specified by the x and y aesthetics. Optionally plot multiple polygons according to the group or color aesthetics.  order controls whether the polygon(s) are underneath or on top of other forms.  If fill is true, fill and stroke the polygons according to Theme.discrete_highlight_color, otherwise only stroke.  If preserve_order is true, connect points in the order they are given, otherwise order the points around their centroid.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.rectbin",
    "page": "Geometries",
    "title": "Gadfly.Geom.rectbin",
    "category": "type",
    "text": "Geom.rectbin\n\nDraw equal sizes rectangles centered at x and y positions.  Optionally specify their color.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.ribbon",
    "page": "Geometries",
    "title": "Gadfly.Geom.ribbon",
    "category": "type",
    "text": "Geom.ribbon\n\nDraw a ribbon at the positions in x bounded above and below by ymax and ymin, respectively.  Optionally draw multiple ribbons by grouping with color.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.segment",
    "page": "Geometries",
    "title": "Gadfly.Geom.segment",
    "category": "type",
    "text": "Geom.segment[(; arrow=false, filled=false)]\n\nDraw line segments from x, y to xend, yend.  Optionally specify their color.  If arrow is true a Scale object for both axes must be provided.  If filled is true the arrows are drawn with a filled polygon, otherwise with a stroked line.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.subplot_grid",
    "page": "Geometries",
    "title": "Gadfly.Geom.subplot_grid",
    "category": "type",
    "text": "Geom.subplot_grid[(elements...)]\n\nDraw multiple subplots in a grid organized by one or two categorial vectors.\n\nOptional Aesthetics\n\nxgroup, ygroup: Arrange subplots on the X and Y axes, respectively, by categorial data.\nfree_x_axis, free_y_axis: Whether the X and Y axis scales, respectively, can differ across the subplots. Defaults to false. If true, scales are set appropriately for individual subplots.\n\nOne or both of xgroup or ygroup must be bound. If only one, a single column or row of subplots is drawn, if both, a grid.\n\nArguments\n\nUnlike most geometries, Geom.subplot_grid is typically passed one or more parameters. The constructor works for the most part like the layer function. Arbitrary plot elements may be passed, while aesthetic bindings are inherited from the parent plot.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.violin",
    "page": "Geometries",
    "title": "Gadfly.Geom.violin",
    "category": "type",
    "text": "Geom.violin[(; order=1)]\n\nDraw y versus width, optionally grouping categorically by x and coloring with color.  Alternatively, if width is not supplied, the data in y will be transformed to a density estimate using Stat.violin\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.vline",
    "page": "Geometries",
    "title": "Gadfly.Geom.vline",
    "category": "type",
    "text": "Geom.vline[(; color=nothing, size=nothing, style=nothing)]\n\nDraw vertical lines across the plot canvas at each position in the xintercept aesthetic.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.xerrorbar",
    "page": "Geometries",
    "title": "Gadfly.Geom.xerrorbar",
    "category": "type",
    "text": "Geom.xerrorbar\n\nDraw horizontal error bars at y from xmin to xmax.  Optionally color them with color.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.yerrorbar",
    "page": "Geometries",
    "title": "Gadfly.Geom.yerrorbar",
    "category": "type",
    "text": "Geom.yerrorbar\n\nDraw vertical error bars at x from ymin to ymax.  Optionally color them with color.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.contour-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.contour",
    "category": "method",
    "text": "Geom.contours[(; levels=15, samples=150, preserve_order=true)]\n\nDraw contour lines of the 2D function, matrix, or DataFrame in the z aesthetic.  This geometry is equivalent to Geom.line with Stat.contour; see the latter for more information.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.density-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.density",
    "category": "method",
    "text": "Geom.density[(; bandwidth=-Inf)]\n\nDraw a line showing the density estimate of the x aesthetic. This geometry is equivalent to Geom.line with Stat.density; see the latter for more information.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.density2d-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.density2d",
    "category": "method",
    "text": "Geom.density2d[(; bandwidth=(-Inf,-Inf), levels=15)]\n\nDraw a set of contours showing the density estimate of the x and y aesthetics.  This geometry is equivalent to Geom.line with Stat.density2d; see the latter for more information.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.ellipse-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.ellipse",
    "category": "method",
    "text": "Geom.ellipse[(; distribution=MvNormal, levels=[0.95], nsegments=51, fill=false)]\n\nDraw a confidence ellipse, using a parametric multivariate distribution, for a scatter of points specified by the x and y aesthetics.  Optionally plot multiple ellipses according to the group or color aesthetics.  This geometry is equivalent to Geom.polygon with Stat.ellipse; see the latter for more information.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.hair-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.hair",
    "category": "method",
    "text": "Geom.hair[(; intercept=0.0, orientation=:vertical)]\n\nDraw lines from x, y to y=intercept if orientation is :vertical or x=intercept if :horizontal.  Optionally specify their color.  This geometry is equivalent to Geom.segment with Stat.hair.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.histogram-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.histogram",
    "category": "method",
    "text": "Geom.histogram[(; position=:stack, bincount=nothing, minbincount=3, maxbincount=150,\n                orientation=:vertical, density=false)]\n\nDraw histograms from a series of observations in x or y optionally grouping by color.  This geometry is equivalent to Geom.bar with Stat.histogram; see the latter for more information.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.histogram2d-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.histogram2d",
    "category": "method",
    "text": "Geom.histogram2d[(; xbincount=nothing, xminbincount=3, xmaxbincount=150,\n                    ybincount=nothing, yminbincount=3, ymaxbincount=150)]\n\nDraw a heatmap of the x and y aesthetics by binning into rectangles and indicating density with color.  This geometry is equivalent to Geom.rect with Stat.histogram2d;  see the latter for more information.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.path-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.path",
    "category": "method",
    "text": "Geom.path\n\nDraw lines between x and y points in the order they are listed.  This geometry is equivalent to Geom.line with preserve_order=true.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.rect-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.rect",
    "category": "method",
    "text": "Geom.rect\n\nDraw colored rectangles with the corners specified by the xmin, xmax, ymin and ymax aesthetics.  Optionally specify their color.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.smooth-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.smooth",
    "category": "method",
    "text": "Geom.smooth[(; method:loess, smoothing=0.75)]\n\nPlot a smooth function estimated from the line described by x and y aesthetics.  Optionally group by color and plot multiple independent smooth lines.  This geometry is equivalent to Geom.line with Stat.smooth; see the latter for more information.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.step-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.step",
    "category": "method",
    "text": "Geom.step[(; direction=:hv)]\n\nConnect points described by the x and y aesthetics using a stepwise function.  Optionally group by color or group.  This geometry is equivalent to Geom.line with Stat.step; see the latter for more information.\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.vector-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.vector",
    "category": "method",
    "text": "Geom.vector[(; filled=false)]\n\nThis geometry is equivalent to Geom.segment(arrow=true).\n\n\n\n"
},

{
    "location": "lib/geometries.html#Gadfly.Geom.vectorfield-Tuple{}",
    "page": "Geometries",
    "title": "Gadfly.Geom.vectorfield",
    "category": "method",
    "text": "Geom.vectorfield[(; smoothness=1.0, scale=1.0, samples=20, filled=false)]\n\nDraw a gradient vector field of the 2D function or a matrix in the z aesthetic.  This geometry is equivalent to Geom.segment with Stat.vectorfield; see the latter for more information.\n\n\n\n"
},

{
    "location": "lib/geometries.html#lib_geom-1",
    "page": "Geometries",
    "title": "Geometries",
    "category": "section",
    "text": "Geometries are responsible for actually doing the drawing. A geometry takes as input one or more aesthetics, and use data bound to these aesthetics to draw things. For instance, the Geom.point geometry draws points using the x and y aesthetics, while the Geom.line geometry draws lines with those same two aesthetics.Core geometries:Modules = [Geom]\nOrder = [:type]Derived geometries build on core geometries by automatically applying a default statistic:Modules = [Geom]\nOrder = [:function]Modules = [Geom]"
},

{
    "location": "lib/guides.html#",
    "page": "Guides",
    "title": "Guides",
    "category": "page",
    "text": "Author = \"Daniel C. Jones\""
},

{
    "location": "lib/guides.html#Gadfly.Guide.annotation",
    "page": "Guides",
    "title": "Gadfly.Guide.annotation",
    "category": "type",
    "text": "Guide.annotation(ctx::Compose.Context)\n\nOverlay a plot with an arbitrary Compose graphic. The context will inherit the plot\'s coordinate system, unless overridden with a custom unit box.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.colorkey",
    "page": "Guides",
    "title": "Gadfly.Guide.colorkey",
    "category": "type",
    "text": "Guide.colorkey[(; title=nothing, labels=nothing, pos=nothing)]\nGuide.colorkey(title, labels, pos)\n\nEnable control of the auto-generated colorkey.  Set the colorkey title for any plot, and the item labels for plots with a discrete color scale.  pos overrides Theme(key_position=) and can be in either relative (e.g. [0.7w, 0.2h] is the lower right quadrant), absolute (e.g. [0mm, 0mm]), or plot scale (e.g. [0,0]) coordinates.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.manual_color_key",
    "page": "Guides",
    "title": "Gadfly.Guide.manual_color_key",
    "category": "type",
    "text": "Guide.manual_color_key(title, labels, colors)\n\nManually define a color key with the legend title and item labels and colors.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.shapekey",
    "page": "Guides",
    "title": "Gadfly.Guide.shapekey",
    "category": "type",
    "text": "Guide.shapekey[(; title=\"Shape\", labels=[\"\"], pos=Float64[])]\nGuide.shapekey(title, labels, pos)\n\nEnable control of the auto-generated shapekey.  Set the key title and the item labels. pos overrides Theme(key_position=) and can be in either relative (e.g. [0.7w, 0.2h] is the lower right quadrant), absolute (e.g. [0mm, 0mm]), or plot scale (e.g. [0,0]) coordinates.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.title",
    "page": "Guides",
    "title": "Gadfly.Guide.title",
    "category": "type",
    "text": "Geom.title(title)\n\nSet the plot title.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.xlabel",
    "page": "Guides",
    "title": "Gadfly.Guide.xlabel",
    "category": "type",
    "text": "Guide.xlabel(label, orientation=:auto)\n\nSets the x-axis label for the plot.  label is either a String or nothing. orientation can also be :horizontal or :vertical.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.xrug",
    "page": "Guides",
    "title": "Gadfly.Guide.xrug",
    "category": "type",
    "text": "Guide.xrug\n\nDraw a short vertical lines along the x-axis of a plot at the positions in the x aesthetic.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.xticks",
    "page": "Guides",
    "title": "Gadfly.Guide.xticks",
    "category": "type",
    "text": "Guide.xticks[(; label=true, ticks=:auto, orientation=:auto)]\nGuide.xticks(label, ticks, orientation)\n\nFormats the tick marks and labels for the x-axis.  label toggles the label visibility.  ticks can also be an array of locations, or nothing. orientation can also be :horizontal or :vertical.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.ylabel",
    "page": "Guides",
    "title": "Gadfly.Guide.ylabel",
    "category": "type",
    "text": "Guide.ylabel(label, orientation=:auto)\n\nSets the y-axis label for the plot.  label is either a String or nothing. orientation can also be :horizontal or :vertical.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.yrug",
    "page": "Guides",
    "title": "Gadfly.Guide.yrug",
    "category": "type",
    "text": "Guide.yrug\n\nDraw short horizontal lines along the y-axis of a plot at the positions in the \'y\' aesthetic.\n\n\n\n"
},

{
    "location": "lib/guides.html#Gadfly.Guide.yticks",
    "page": "Guides",
    "title": "Gadfly.Guide.yticks",
    "category": "type",
    "text": "Guide.yticks[(; label=true, ticks=:auto, orientation=:horizontal)]\nGuide.yticks(ticks, label, orientation)\n\nFormats the tick marks and labels for the y-axis.  label toggles the label visibility.  ticks can also be an array of locations, or nothing. orientation can also be :auto or :vertical.\n\n\n\n"
},

{
    "location": "lib/guides.html#lib_guide-1",
    "page": "Guides",
    "title": "Guides",
    "category": "section",
    "text": "Very similar to Geometries are guides, which draw graphics supporting the actual visualization, such as axis ticks, axis labels, and color keys. The major distinction is that geometries always draw within the rectangular plot frame, while guides have some special layout considerations.Modules = [Guide]Modules = [Guide]"
},

{
    "location": "lib/statistics.html#",
    "page": "Statistics",
    "title": "Statistics",
    "category": "page",
    "text": "Author = \"Daniel C. Jones\""
},

{
    "location": "lib/statistics.html#Gadfly.Stat.xticks-Tuple{}",
    "page": "Statistics",
    "title": "Gadfly.Stat.xticks",
    "category": "method",
    "text": "Stat.xticks[(; ticks=:auto, granularity_weight=1/4, simplicity_weight=1/6,\n            coverage_weight=1/3, niceness_weight=1/4)]\n\nCompute an appealing set of x-ticks that encompass the data by transforming the x, xmin, xmax and xintercept aesthetics into the xtick and xgrid aesthetics.  ticks is a vector of desired values, or :auto to indicate they should be computed.  the importance of having a reasonable number of ticks is specified with granularity_weight; of including zero with simplicity_weight; of tightly fitting the span of the data with coverage_weight; and of having a nice numbering with niceness_weight.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.yticks-Tuple{}",
    "page": "Statistics",
    "title": "Gadfly.Stat.yticks",
    "category": "method",
    "text": "Stat.yticks[(; ticks=:auto, granularity_weight=1/4, simplicity_weight=1/6,\n            coverage_weight=1/3, niceness_weight=1/4)]\n\nCompute an appealing set of y-ticks that encompass the data by transforming the y, ymin, ymax, yintercept, middle, lower_hinge, upper_hinge, lower_fence and upper_fence aesthetics into the ytick and ygrid aesthetics.  ticks is a vector of desired values, or :auto to indicate they should be computed.  the importance of having a reasonable number of ticks is specified with granularity_weight; of including zero with simplicity_weight; of tightly fitting the span of the data with coverage_weight; and of having a nice numbering with niceness_weight.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.bar",
    "page": "Statistics",
    "title": "Gadfly.Stat.bar",
    "category": "type",
    "text": "Stat.bar[(; position=:stack, orientation=:vertical)]\n\nTransform the x aesthetic into the xmin and xmax aesthetics.  Used by Geom.bar.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.binmean",
    "page": "Statistics",
    "title": "Gadfly.Stat.binmean",
    "category": "type",
    "text": "Stat.binmean[(; n=20)]\n\nTransform the the x and y aesthetics into n bins each of which contains the mean within than bin.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.boxplot",
    "page": "Statistics",
    "title": "Gadfly.Stat.boxplot",
    "category": "type",
    "text": "Stat.boxplot[(; method=:tukey)]\n\nTransform the the x and y aesthetics into the x, middle, lower_hinge, upper_hinge, lower_fence, upper_fence and outliers aesthetics.  If method is :tukey then Tukey\'s rule is used (i.e. fences are 1.5 times the inter-quartile range).  Otherwise, a vector of five numbers giving quantiles for lower fence, lower hinge, middle, upper hinge, and upper fence in that order.  Used by Geom.boxplot.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.contour",
    "page": "Statistics",
    "title": "Gadfly.Stat.contour",
    "category": "type",
    "text": "Stat.contour[(; levels=15, samples=150)]\n\nTransform the 2D function, matrix, DataFrame in the z aesthetic into a set of lines in x and y showing the iso-level contours.  A function requires that either the x and y or the xmin, xmax, ymin and ymax aesthetics also be defined.  The latter are interpolated using samples.  A matrix and DataFrame can optionally input x and y aesthetics to specify the coordinates of the rows and columns, respectively.  In each case levels sets the number of contours to draw:  either a vector of contour levels, an integer that specifies the number of contours to draw, or a function which inputs z and outputs either a vector or an integer.  Used by Geom.contour.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.density",
    "page": "Statistics",
    "title": "Gadfly.Stat.density",
    "category": "type",
    "text": "Stat.density[(; n=256, bandwidth=-Inf)]\n\nEstimate the density of x at n points, and put the result in x and y. Smoothing is controlled by bandwidth.  Used by Geom.density.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.density2d",
    "page": "Statistics",
    "title": "Gadfly.Stat.density2d",
    "category": "type",
    "text": "Stat.density2d[(; n=(256,256), bandwidth=(-Inf,-Inf), levels=15)]\n\nEstimate the density of the x and y aesthetics at n points and put the results into the x, y and z aesthetics.  Smoothing is controlled by bandwidth.  Calls Stat.contour to compute the levels.  Used by Geom.density2d.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.ellipse",
    "page": "Statistics",
    "title": "Gadfly.Stat.ellipse",
    "category": "type",
    "text": "Stat.ellipse[(; distribution=MvNormal, levels=[0.95], nsegments=51)]\n\nTransform the points in the x and y aesthetics into set of a lines in the x and y aesthetics.  distribution specifies a multivariate distribution to use; levels the quantiles for which confidence ellipses are calculated; and nsegments the number of segments with which to draw each ellipse.  Used by Geom.ellipse.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.func",
    "page": "Statistics",
    "title": "Gadfly.Stat.func",
    "category": "type",
    "text": "Stat.func[(; num_samples=250)]\n\nTransform the functions or expressions in the y, xmin and xmax aesthetics into points in the x, y and group aesthetics.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.hair",
    "page": "Statistics",
    "title": "Gadfly.Stat.hair",
    "category": "type",
    "text": "Stat.hair[(; intercept=0.0, orientation=:vertical)]\n\nTransform points in the x and y aesthetics into lines in the x, y, xend and yend aesthetics.  Used by Geom.hair.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.hexbin",
    "page": "Statistics",
    "title": "Gadfly.Stat.hexbin",
    "category": "type",
    "text": "Stat.hexbin[(; xbincount=50, ybincount=50)]\n\nBin the points in the x and y aesthetics into hexagons in the x, y, xsize and ysize aesthetics.  xbincount and ybincount manually fix the number of bins.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.histogram",
    "page": "Statistics",
    "title": "Gadfly.Stat.histogram",
    "category": "type",
    "text": "Stat.histogram[(; bincount=nothing, minbincount=3, maxbincount=150,\n                position=:stack, orientation=:vertical, density=false)]\n\nTransform the x aesthetic into the x, y, xmin and xmax aesthetics, optionally grouping by color. Exchange y for x when orientation is :horizontal.  bincount specifies the number of bins to use.  If set to nothing, an optimization method is used to determine a reasonable value which uses minbincount and maxbincount to set the lower and upper limits.  If density is true, normalize the counts by their total.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.histogram2d",
    "page": "Statistics",
    "title": "Gadfly.Stat.histogram2d",
    "category": "type",
    "text": "Stat.histogram2d[(; xbincount=nothing, xminbincount=3, xmaxbincount=150,\n                    ybincount=nothing, yminbincount=3, ymaxbincount=150)]\n\nBin the points in the x and y aesthetics into rectangles in the xmin, ymax, ymin, ymax and color aesthetics.  xbincount and ybincount manually fix the number of bins.  If set to nothing, an optimization method is used to determine a reasonable value which uses xminbincount, xmaxbincount, yminbincount and ymaxbincount to set the lower and upper limits.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.identity",
    "page": "Statistics",
    "title": "Gadfly.Stat.identity",
    "category": "type",
    "text": "Stat.identity\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.nil",
    "page": "Statistics",
    "title": "Gadfly.Stat.nil",
    "category": "type",
    "text": "Stat.Nil\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.qq",
    "page": "Statistics",
    "title": "Gadfly.Stat.qq",
    "category": "type",
    "text": "Stat.qq\n\nTransform the x and y aesthetics into cumulative distrubutions. If each is a numeric vector, their sample quantiles will be compared.  If one is a Distribution, then its theoretical quantiles will be compared with the sample quantiles of the other.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.rectbin",
    "page": "Statistics",
    "title": "Gadfly.Stat.rectbin",
    "category": "type",
    "text": "Stat.rectbin\n\nTransform the x and y aesthetics into the xmin, xmax, ymin and ymax aesthetics.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.smooth",
    "page": "Statistics",
    "title": "Gadfly.Stat.smooth",
    "category": "type",
    "text": "Stat.smooth[(; method=:loess, smoothing=0.75)]\n\nTransform the x and y aesthetics into the x and y aesthetics.  method can either be:loess or :lm.  smoothing controls the degree of smoothing.  For :loess, this is the span parameter giving the proportion of data used for each local fit where 0.75 is the default. Smaller values use more data (less local context), larger values use less data (more local context).\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.step",
    "page": "Statistics",
    "title": "Gadfly.Stat.step",
    "category": "type",
    "text": "Stat.step[(; direction=:hv)]\n\nPerform stepwise interpolation between the points in the x and y aesthetics.  If direction is :hv a horizontal line extends to the right of each point and a vertical line below it;  if :vh then vertical above and horizontal to the left.  More concretely, between (x[i], y[i]) and (x[i+1], y[i+1]), either (x[i+1], y[i]) or (x[i], y[i+1]) is inserted, for :hv and :vh, respectively.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.vectorfield",
    "page": "Statistics",
    "title": "Gadfly.Stat.vectorfield",
    "category": "type",
    "text": "Stat.vectorfield[(; smoothness=1.0, scale=1.0, samples=20)]\n\nTransform the 2D function or matrix in the z aesthetic into a set of lines from x, y to xend, yend showing the gradient vectors.  A function requires that either the x and y or the xmin, xmax, ymin and ymax aesthetics also be defined.  The latter are interpolated using samples.  A matrix can optionally input x and y aesthetics to specify the coordinates of the rows and columns, respectively.  In each case, smoothness can vary from 0 to Inf;  and scale sets the size of vectors.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.violin",
    "page": "Statistics",
    "title": "Gadfly.Stat.violin",
    "category": "type",
    "text": "Stat.violin[(n=300)]\n\nTransform the x, y and color aesthetics.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.x_jitter-Tuple{}",
    "page": "Statistics",
    "title": "Gadfly.Stat.x_jitter",
    "category": "method",
    "text": "Stat.x_jitter[(; range=0.8, seed=0x0af5a1f7)]\n\nAdd a random number to the x aesthetic, which is typically categorical, to reduce the likelihood that points overlap.  The maximum jitter is range times the smallest non-zero difference between two points.\n\n\n\n"
},

{
    "location": "lib/statistics.html#Gadfly.Stat.y_jitter-Tuple{}",
    "page": "Statistics",
    "title": "Gadfly.Stat.y_jitter",
    "category": "method",
    "text": "Stat.y_jitter[(; range=0.8, seed=0x0af5a1f7)]\n\nAdd a random number to the y aesthetic, which is typically categorical, to reduce the likelihood that points overlap.  The maximum jitter is range times the smallest non-zero difference between two points.\n\n\n\n"
},

{
    "location": "lib/statistics.html#lib_stat-1",
    "page": "Statistics",
    "title": "Statistics",
    "category": "section",
    "text": "Statistics are functions taking as input one or more aesthetics, operating on those values, then outputting to one or more aesthetics. For example, drawing of boxplots typically uses the boxplot statistic (Stat.boxplot) that takes as input the x and y aesthetic, and outputs the middle, and upper and lower hinge, and upper and lower fence aesthetics.Modules = [Stat]Modules = [Stat]"
},

{
    "location": "lib/coordinates.html#",
    "page": "Coordinates",
    "title": "Coordinates",
    "category": "page",
    "text": "Author = \"Tamas Nagy\""
},

{
    "location": "lib/coordinates.html#Gadfly.Coord.cartesian",
    "page": "Coordinates",
    "title": "Gadfly.Coord.cartesian",
    "category": "type",
    "text": "Coord.cartesian(; xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing,\n                xflip=false, yflip=false,\n                aspect_ratio=nothing, fixed=false,\n                raster=false)\n\nxmin, xmax, ymin, and ymax specify hard minimum and maximum values on the x and y axes, and override the soft limits in Scale.x_continuous and Scale.y_continuous.  if xflip or yflip are true the respective axis is flipped.  aspect_ratio fulfills its namesake if not nothing, unless overridden by a fixed value of true, in which case the aspect ratio follows the units of the plot (e.g. if the y-axis is 5 units high and the x-axis in 10 units across, the plot will be drawn at an aspect ratio of 2).\n\n\n\n"
},

{
    "location": "lib/coordinates.html#lib_coord-1",
    "page": "Coordinates",
    "title": "Coordinates",
    "category": "section",
    "text": "Coordinate systems are mappings between a coordinate space and the 2D rendered output.  Currently there is only 2D Cartesian, but this would be the mechanism to implement polar, barycentric, etc. and even projections of their 3D counterparts.Modules = [Coord]Modules = [Coord]"
},

{
    "location": "lib/scales.html#",
    "page": "Scales",
    "title": "Scales",
    "category": "page",
    "text": "Author = \"Daniel C. Jones\""
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_identity",
    "page": "Scales",
    "title": "Gadfly.Scale.color_identity",
    "category": "type",
    "text": "color_identity\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_none",
    "page": "Scales",
    "title": "Gadfly.Scale.color_none",
    "category": "type",
    "text": "color_none\n\nSuppress the default color scale that some statistics impose by setting the color aesthetic to nothing.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.label",
    "page": "Scales",
    "title": "Gadfly.Scale.label",
    "category": "type",
    "text": "label\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_asinh",
    "page": "Scales",
    "title": "Gadfly.Scale.color_asinh",
    "category": "function",
    "text": "color_asinh[(; minvalue=nothing, maxvalue=nothing, colormap)]\n\nSimilar to Scale.color_continuous, except that color is asinh transformed.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_continuous",
    "page": "Scales",
    "title": "Gadfly.Scale.color_continuous",
    "category": "function",
    "text": "color_continuous[(; minvalue=nothing, maxvalue=nothing, colormap)]\n\nCreate a continuous color scale by mapping the color aesthetic to a Color.  minvalue and maxvalue specify the data values corresponding to the bottom and top of the color scale.  colormap is a function defined on the interval from 0 to 1 that returns a Color.\n\nEither input Stat.color_continuous as an argument to plot, or set continuous_color_scale in a Theme.\n\nSee also color_log10, color_log2, color_log, color_asinh, and color_sqrt.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_discrete_hue",
    "page": "Scales",
    "title": "Gadfly.Scale.color_discrete_hue",
    "category": "function",
    "text": "color_discrete_hue[(f; levels=nothing, order=nothing, preserve_order=true)]\n\nCreate a discrete color scale that maps the categorical levels in the color aesthetic to Colors.  f is a function that produces a vector of colors. levels gives values for the scale.  Order will be respected and anything in the data that\'s not represented in levels will be set to missing.  order is a vector of integers giving a permutation of the levels default order.  If preserve_order is true orders levels as they appear in the data.\n\nEither input Stat.color_discrete_hue as an argument to plot, or set discrete_color_scale in a Theme.\n\nExamples\n\njulia> x = Scale.color_discrete_hue()\nGadfly.Scale.DiscreteColorScale(Gadfly.Scale.default_discrete_colors, nothing, nothing, true)\n\njulia> x.f(3)\n3-element Array{ColorTypes.Color,1}:\n LCHab{Float32}(70.0,60.0,240.0)        \n LCHab{Float32}(80.0,70.0,100.435)      \n LCHab{Float32}(65.8994,62.2146,353.998)\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_discrete_manual-Tuple{Vararg{AbstractString,N} where N}",
    "page": "Scales",
    "title": "Gadfly.Scale.color_discrete_manual",
    "category": "method",
    "text": "color_discrete_manual(colors...; levels=nothing, order=nothing)\n\nSimilar to color_discrete_hue except that colors for each level are specified directly instead of being computed by a function.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_log",
    "page": "Scales",
    "title": "Gadfly.Scale.color_log",
    "category": "function",
    "text": "color_log[(; minvalue=nothing, maxvalue=nothing, colormap)]\n\nSimilar to Scale.color_continuous, except that color is log transformed.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_log10",
    "page": "Scales",
    "title": "Gadfly.Scale.color_log10",
    "category": "function",
    "text": "color_log10[(; minvalue=nothing, maxvalue=nothing, colormap)]\n\nSimilar to Scale.color_continuous, except that color is log10 transformed.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_log2",
    "page": "Scales",
    "title": "Gadfly.Scale.color_log2",
    "category": "function",
    "text": "color_log2[(; minvalue=nothing, maxvalue=nothing, colormap)]\n\nSimilar to Scale.color_continuous, except that color is log2 transformed.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.color_sqrt",
    "page": "Scales",
    "title": "Gadfly.Scale.color_sqrt",
    "category": "function",
    "text": "color_sqrt[(; minvalue=nothing, maxvalue=nothing, colormap)]\n\nSimilar to Scale.color_continuous, except that color is sqrt transformed.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.group_discrete-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.group_discrete",
    "category": "method",
    "text": "group_discrete[(; labels=nothing, levels=nothing, order=nothing)]\n\nSimilar to Scale.x_discrete, except applied to the group aesthetic.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.lab_gradient-Tuple{Vararg{ColorTypes.Color,N} where N}",
    "page": "Scales",
    "title": "Gadfly.Scale.lab_gradient",
    "category": "method",
    "text": "function lab_gradient(cs::Color...)\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.lab_rainbow-NTuple{4,Any}",
    "page": "Scales",
    "title": "Gadfly.Scale.lab_rainbow",
    "category": "method",
    "text": "lab_rainbow(l, c, h0, n)\n\nGenerate n colors in the LCHab colorspace by using a fixed luminance l and chroma c, and varying the hue, starting at h0.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.lchabmix-NTuple{4,Any}",
    "page": "Scales",
    "title": "Gadfly.Scale.lchabmix",
    "category": "method",
    "text": "function lchabmix(c0_, c1_, r, power)\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.luv_rainbow-NTuple{4,Any}",
    "page": "Scales",
    "title": "Gadfly.Scale.luv_rainbow",
    "category": "method",
    "text": "luv_rainbow(l, c, h0, n)\n\nGenerate n colors in the LCHuv colorspace by using a fixed luminance l and chroma c, and varying the hue, starting at h0.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.shape_discrete-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.shape_discrete",
    "category": "method",
    "text": "shape_discrete[(; labels=nothing, levels=nothing, order=nothing)]\n\nSimilar to Scale.x_discrete, except applied to the shape aesthetic.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.shape_identity-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.shape_identity",
    "category": "method",
    "text": "shape_identity()\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.size_continuous",
    "page": "Scales",
    "title": "Gadfly.Scale.size_continuous",
    "category": "function",
    "text": "size_continuous[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                 format=nothing, minticks=2, maxticks=10, scalable=true)]\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.size_discrete-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.size_discrete",
    "category": "method",
    "text": "size_discrete[(; labels=nothing, levels=nothing, order=nothing)]\n\nSimilar to Scale.x_discrete, except applied to the size aesthetic.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.size_identity-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.size_identity",
    "category": "method",
    "text": "size_identity()\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.weighted_color_mean-Union{Tuple{AbstractArray{ColorTypes.Lab{T},1},AbstractArray{S,1}}, Tuple{S}, Tuple{T}} where T where S<:Number",
    "page": "Scales",
    "title": "Gadfly.Scale.weighted_color_mean",
    "category": "method",
    "text": "function weighted_color_mean(cs::AbstractArray{Lab{T},1},\n                             ws::AbstractArray{S,1}) where {S <: Number,T}\n\nReturn the mean of Lab colors cs as weighted by ws.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.x_asinh",
    "page": "Scales",
    "title": "Gadfly.Scale.x_asinh",
    "category": "function",
    "text": "x_asinh[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.x_continuous, except that the aesthetics are asinh transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.x_continuous",
    "page": "Scales",
    "title": "Gadfly.Scale.x_continuous",
    "category": "function",
    "text": "x_continuous[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nMap the x, xmin, xmax, xintercept, intercept, xviewmin, xviewmax and xend aesthetics to x positions in Cartesian coordinates, which are presumed to be numerical, using an identity transform.  minvalue and maxvalue set soft lower and upper bounds.  (Use Coord.cartesian to enforce a hard bound.)  labels is a function which maps a coordinate value to a string label.  format is one of :plain, :scientific, :engineering, or :auto. Set scalable to false to prevent zooming on this axis.  See also x_log10, x_log2, x_log, x_asinh, and x_sqrt for alternatives to the identity transform.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.x_discrete-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.x_discrete",
    "category": "method",
    "text": "x_discrete[(; labels=nothing, levels=nothing, order=nothing)]\n\nMap the x, xmin, xmax, xintercept, intercept, xviewmin, xviewmax and xend aesthetics, which are presumed to be categorical, to Cartesian coordinates. Unlike Scale.x_continuous, each unique x value will be mapped to equally spaced positions, regardless of value.\n\nBy default continuous scales are applied to numerical data. If data consists of numbers specifying categories, explicitly adding Scale.x_discrete is the easiest way to get that data to plot appropriately.\n\nlabels is either a function which maps a coordinate value to a string label, or a vector of strings of the same length as the number of unique values in the aesthetic.  levels gives values for the scale.  Order will be respected and anything in the data that\'s not respresented in levels will be set to missing.  order is a vector of integers giving a permutation of the levels default order.\n\nSee also group_discrete, shape_discrete, and size_discrete.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.x_distribution-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.x_distribution",
    "category": "method",
    "text": "x_distribution()\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.x_log",
    "page": "Scales",
    "title": "Gadfly.Scale.x_log",
    "category": "function",
    "text": "x_log[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.x_continuous, except that the aesthetics are log transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.x_log10",
    "page": "Scales",
    "title": "Gadfly.Scale.x_log10",
    "category": "function",
    "text": "x_log10[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.x_continuous, except that the aesthetics are log10 transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.x_log2",
    "page": "Scales",
    "title": "Gadfly.Scale.x_log2",
    "category": "function",
    "text": "x_log2[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.x_continuous, except that the aesthetics are log2 transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.x_sqrt",
    "page": "Scales",
    "title": "Gadfly.Scale.x_sqrt",
    "category": "function",
    "text": "x_sqrt[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.x_continuous, except that the aesthetics are sqrt transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.xgroup-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.xgroup",
    "category": "method",
    "text": "xgroup[(; labels=nothing, levels=nothing, order=nothing)]\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.y_asinh",
    "page": "Scales",
    "title": "Gadfly.Scale.y_asinh",
    "category": "function",
    "text": "y_asinh[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.y_continuous, except that the aesthetics are asinh transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.y_continuous",
    "page": "Scales",
    "title": "Gadfly.Scale.y_continuous",
    "category": "function",
    "text": "y_continuous[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nMap the y, ymin, ymax, yintercept, slope, middle, upper_fence, lower_fence, upper_hinge, lower_hinge, yviewmin, yviewmax and yend aesthetics to y positions in Cartesian coordinates, which are presumed to be numerical, using an identity transform.  minvalue and maxvalue set soft lower and upper bounds.  (Use Coord.cartesian to enforce a hard bound.)  labels is a function which maps a coordinate value to a string label.  format is one of :plain, :scientific, :engineering, or :auto. Set scalable to false to prevent zooming on this axis.  See also y_log10, y_log2, y_log, y_asinh, and y_sqrt for alternatives to the identity transform.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.y_discrete-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.y_discrete",
    "category": "method",
    "text": "y_discrete[(; labels=nothing, levels=nothing, order=nothing)]\n\nMap the y, ymin, ymax, yintercept, slope, middle, upper_fence, lower_fence, upper_hinge, lower_hinge, yviewmin, yviewmax and yend aesthetics, which are presumed to be categorical, to Cartesian coordinates. Unlike Scale.x_continuous, each unique y value will be mapped to equally spaced positions, regardless of value.\n\nBy default continuous scales are applied to numerical data. If data consists of numbers specifying categories, explicitly adding Scale.y_discrete is the easiest way to get that data to plot appropriately.\n\nlabels is either a function which maps a coordinate value to a string label, or a vector of strings of the same length as the number of unique values in the aesthetic.  levels gives values for the scale.  Order will be respected and anything in the data that\'s not respresented in levels will be set to missing.  order is a vector of integers giving a permutation of the levels default order.\n\nSee also group_discrete, shape_discrete, and size_discrete.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.y_distribution-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.y_distribution",
    "category": "method",
    "text": "y_distribution()\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.y_func-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.y_func",
    "category": "method",
    "text": "y_func()\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.y_log",
    "page": "Scales",
    "title": "Gadfly.Scale.y_log",
    "category": "function",
    "text": "y_log[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.y_continuous, except that the aesthetics are log transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.y_log10",
    "page": "Scales",
    "title": "Gadfly.Scale.y_log10",
    "category": "function",
    "text": "y_log10[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.y_continuous, except that the aesthetics are log10 transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.y_log2",
    "page": "Scales",
    "title": "Gadfly.Scale.y_log2",
    "category": "function",
    "text": "y_log2[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.y_continuous, except that the aesthetics are log2 transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.y_sqrt",
    "page": "Scales",
    "title": "Gadfly.Scale.y_sqrt",
    "category": "function",
    "text": "y_sqrt[(; minvalue=nothing, maxvalue=nothing, labels=nothing,\n                   format=nothing, minticks=2, maxticks=10, scalable=true)]\n\nSimilar to Scale.y_continuous, except that the aesthetics are sqrt transformed and the labels function inputs transformed values.\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.ygroup-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.ygroup",
    "category": "method",
    "text": "ygroup[(; labels=nothing, levels=nothing, order=nothing)]\n\n\n\n"
},

{
    "location": "lib/scales.html#Gadfly.Scale.z_func-Tuple{}",
    "page": "Scales",
    "title": "Gadfly.Scale.z_func",
    "category": "method",
    "text": "z_func()\n\n\n\n"
},

{
    "location": "lib/scales.html#lib_scale-1",
    "page": "Scales",
    "title": "Scales",
    "category": "section",
    "text": "Scales, similarly to Statistics, apply a transformation to the original data, typically mapping one aesthetic to the same aesthetic, while retaining the original value. For example, the Scale.x_log10 aesthetic maps the  x aesthetic back to the x aesthetic after applying a log10 transformation, but keeps track of the original value so that data points are properly identified.Modules = [Scale]Modules = [Scale]"
},

{
    "location": "lib/shapes.html#",
    "page": "Shapes",
    "title": "Shapes",
    "category": "page",
    "text": "Author = \"Ben J. Arthur\""
},

{
    "location": "lib/shapes.html#Gadfly.Shape.cross-Tuple{AbstractArray,AbstractArray,AbstractArray}",
    "page": "Shapes",
    "title": "Gadfly.Shape.cross",
    "category": "method",
    "text": "cross(xs, ys, rs)\n\nDraw crosses at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.diamond-Tuple{AbstractArray,AbstractArray,AbstractArray}",
    "page": "Shapes",
    "title": "Gadfly.Shape.diamond",
    "category": "method",
    "text": "diamond(xs, ys, rs)\n\nDraw diamonds at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.dtriangle-Tuple{AbstractArray,AbstractArray,AbstractArray}",
    "page": "Shapes",
    "title": "Gadfly.Shape.dtriangle",
    "category": "method",
    "text": "dtriangle(xs, ys, rs)\n\nDraw downward-pointing triangles at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.hexagon-Tuple{AbstractArray,AbstractArray,AbstractArray}",
    "page": "Shapes",
    "title": "Gadfly.Shape.hexagon",
    "category": "method",
    "text": "hexagon(xs, ys, rs)\n\nDraw hexagons at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.hline-Tuple{AbstractArray,AbstractArray,AbstractArray}",
    "page": "Shapes",
    "title": "Gadfly.Shape.hline",
    "category": "method",
    "text": "hline(xs, ys, rs)\n\nDraw horizontal lines at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.octagon-Tuple{AbstractArray,AbstractArray,AbstractArray}",
    "page": "Shapes",
    "title": "Gadfly.Shape.octagon",
    "category": "method",
    "text": "octagon(xs, ys, rs)\n\nDraw octagons at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.square-Tuple{AbstractArray,AbstractArray,AbstractArray}",
    "page": "Shapes",
    "title": "Gadfly.Shape.square",
    "category": "method",
    "text": "square(xs, ys, rs)\n\nDraw squares at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.star1",
    "page": "Shapes",
    "title": "Gadfly.Shape.star1",
    "category": "function",
    "text": "star1(xs, ys, rs, scalar=1)\n\nDraw five-pointed stars at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.star2",
    "page": "Shapes",
    "title": "Gadfly.Shape.star2",
    "category": "function",
    "text": "star2(xs, ys, rs, scalar=1)\n\nDraw four-pointed stars at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.utriangle",
    "page": "Shapes",
    "title": "Gadfly.Shape.utriangle",
    "category": "function",
    "text": "utriangle(xs, ys, rs, scalar=1)\n\nDraw upward-pointing triangles at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.vline-Tuple{AbstractArray,AbstractArray,AbstractArray}",
    "page": "Shapes",
    "title": "Gadfly.Shape.vline",
    "category": "method",
    "text": "vline(xs, ys, rs)\n\nDraw vertical lines at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Gadfly.Shape.xcross-Tuple{AbstractArray,AbstractArray,AbstractArray}",
    "page": "Shapes",
    "title": "Gadfly.Shape.xcross",
    "category": "method",
    "text": "xcross(xs, ys, rs)\n\nDraw rotated crosses at the coordinates specified in xs and ys of size rs\n\n\n\n"
},

{
    "location": "lib/shapes.html#Shapes-1",
    "page": "Shapes",
    "title": "Shapes",
    "category": "section",
    "text": "Shapes, when combined with Geom.point, specify the appearance of markers.  In addition to those below, circle is also imported from Compose.jl.Modules = [Shape]Modules = [Shape]"
},

{
    "location": "dev/pipeline.html#",
    "page": "Rendering Pipeline",
    "title": "Rendering Pipeline",
    "category": "page",
    "text": "Author = \"Darwin Darakananda\""
},

{
    "location": "dev/pipeline.html#Rendering-Pipeline-1",
    "page": "Rendering Pipeline",
    "title": "Rendering Pipeline",
    "category": "section",
    "text": "using DataFrames\nusing Colors\nusing Compose\nusing RDatasets\nusing Showoff\nusing GadflyHow does the function calldf = dataset(\"ggplot2\", \"diamonds\")\np = plot(df,\n         x = :Price, color = :Cut,\n		 Stat.histogram,\n		 Geom.bar)actually get turned into the following plot?df = dataset(\"ggplot2\", \"diamonds\")\np = plot(df,\n         x = :Price, color = :Cut,\n		 Stat.histogram,\n		 Geom.bar)p # hideThe rendering pipeline transforms a plot specification into a Compose scene graph that contains a set of guides (e.g. axis ticks, color keys) and one or more layers of geometry (e.g. points, lines). The specification of each layer hasa data source (e.g. dataset(\"ggplot2\", \"diamonds\"))\na geometry to represent the layer\'s data (e.g. point, line, etc.)\nmappings to associate aesthetics of the geometry with elements of the data source (e.g.  :color => :Cut)\nlayer-wise statistics (optional) to be applied to the layer\'s dataAll layers of a plot share the sameCoordinates for the geometry (e.g. cartesian, polar, etc.)\naxis Scales (e.g. loglog, semilog, etc.)\nplot-wise Statistics (optional) to be applied to all layers\nGuidesA full plot specification must describe these shared elements as well as all the layer specifications. In the example above, we see that only the data source, statistics, geometry, and mapping are specified. The missing elements are either inferred from the data (e.g. categorical values in df[:Cut] implies a discrete color scale), or assumed using defaults (e.g. continuous x-axis scale). For example, invoking plot with all the elements will look something likep = plot(layer(df,\n               x = :Price, color = :Cut,\n		       Stat.histogram,\n		       Geom.bar),\n	  	 Scale.x_continuous,\n		 Scale.color_discrete,\n		 Coord.cartesian,\n		 Guide.xticks, Guide.yticks,\n		 Guide.xlabel(\"Price\"),\n		 Guide.colorkey(title=\"Cut\"))Once a full plot specification is filled out, the rendering process proceeds as follows:(Image: )For each layer in the plot, we first map subsets of the data source to a Data object. The Price and Cut columns of the diamond dataset are mapped to the :x and :color fields of Data, respectively.\nScales are applied to the data to obtain plottable aesthetics. Scale.x_continuous keeps the values of df[:Price] unchanged, while Scale.color_discrete_hue maps the unique elements of df[:Cut] (an array of strings) to actual color values.\nThe aesthetics are transformed by layer-wise and plot-wise statistics, in order. Stat.histogram replaces the x field of the aesthetics with bin positions, and sets the y field with the corresponding counts.\nUsing the position aesthetics from all layers, we create a Compose context with a coordinate system that fits the data to screen coordinates. Coord.cartesian creates a Compose context that maps a vertical distance of 3000 counts to about two inches in the rendered plot.\nEach layer renders its own geometry.\nFinally, we compute the layout of the guides and render them on top of the plot context."
},

{
    "location": "dev/regression.html#",
    "page": "Regression Testing",
    "title": "Regression Testing",
    "category": "page",
    "text": "Author = \"Ben Arthur\""
},

{
    "location": "dev/regression.html#Regression-Testing-1",
    "page": "Regression Testing",
    "title": "Regression Testing",
    "category": "section",
    "text": "Running Pkg.test(\"Gadfly\") evaluates all of the files in Gadfly/test/testscripts.  Any errors or warnings are printed to the REPL.  In addition, the figures that are produced are put into either the devel-output/ or master-output/ sub-directories.  Nominally, the former represents the changes in a pull request while the latter are used for comparison. Specifically, runtests.jl examines the currently checked out git commit, and sets the output directory to master-output/ if it is the HEAD of the master branch or if it is detached.  Otherwise, it assumes you are at the tip of a development branch and saves the figures to devel-output/.  After running the tests on both of these branches, executing compare_examples.jl displays differences between the new and old figures.  This script can dump a diff of the files to the REPL, open both figures for manual comparison, and/or, for SVG and PNG files, display a black and white figure highlighting the spatial location of the differences.So the automated regression analysis workflow is then as follows:In a branch other than master,\ndevelop your new feature or fix your old bug,\ncommit all your changes,\nPkg.test(\"Gadfly\"),\ncheckout master,\nPkg.test again,\nPkg.add(\"ArgParse\") and, for B&W images, Cairo, Fontconfig, Rsvg, and Images as well,\ncheck for differences with julia test/compare_examples.jl [--diff] [--two] [--bw] [-h] [filter].  For example, julia test/compare_examples.jl --bw .js.svg will show black and white images highlighting the differences between the svg test images."
},

{
    "location": "dev/compose.html#",
    "page": "Relationship with Compose.jl",
    "title": "Relationship with Compose.jl",
    "category": "page",
    "text": "Author = \"Ben Arthur\""
},

{
    "location": "dev/compose.html#Relationship-with-Compose.jl-1",
    "page": "Relationship with Compose.jl",
    "title": "Relationship with Compose.jl",
    "category": "section",
    "text": "Gadfly and Compose are tightly intertwined.  As such, if you want to checkout the master branch of Gadfly to get the latest features and bug fixes, you\'ll likely also need to checkout Compose.Moreover, if you\'re a contributor, you should probably tag releases of Gadfly and Compose simultaneously, and ideally submit a single PR to METADATA containing both.  It is for this reason that neither uses attobot, as it has no mechanism to do this."
},

]}
