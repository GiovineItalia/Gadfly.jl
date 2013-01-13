
Small/Medium projects:
 * Geom.rectbin and Geom.hexbin
 * Continuous color scales.
 * Weave should detect the format of the output of code blocks and embed it
   appropriately.
 * A proper Layer constructor.
 * Something equivalent to xlim/ylim in ggplot2.
 * Discrete color scales with bar charts.
 * Stacked bar charts.
 * Mousing over a point should show text telling its coordinates.
 * Handle NaN and Inf gracefully. NaN should be filtered out it most cases. We
   could handle Inf/-Inf like ggplot2 does by placing points at the very edge of
   the plot, but this can be misleading. Maybe filtering them and issuing a
   warning is better.
 * When a Guide.XLabel/YLabel is supplied it should override the default, rather
   than add another label.
 * A means by which statistics can modify guides. Particularly I need
   Stat.histogram to add the y-axis label of "Count" or "Frequency", but there's
   no way it can currently.
 * An option to choose the orientation of tick labels.
 * A size aesthetic.
 * A shape aesthetic, for drawing point plots with categorization using shapes.
   People are going to want it, despite the fact that most plots of this variety
   are truly terrible. It's often hard to tell which shapes are which, plus
   choice in shapes makes some categories seem more significant than others.
   Think about ways to mitigate the damage.
 * Polar coordinates.
 * Look into embedding SVG fonts and/or using web fonts so plots look roughly
   the same across platforms.
 * Fix glitches in the cairo backend, I think all of which inlove rendering
   text, and would probably be fixed if pango was used for rendering rather than
   the "toy api".
 * Write a function that examines a plot (rendered or otherwise) and reports
   the minimum size needed to render it such that no labels overlap.

Large projects:
 * Zoom/pan in cartesian coordinates: Write javascript to scale everything in
   the plot pane appropriately on mouse events. One really tricky part is
   updating axis ticks and tick labels. Writing javascript to generate new ticks
   would mean maintaing javascript and julia versions of the same code. Probably
   I will just prepare invisible ticks/labels than are revealed/hidden by the
   javascript code when needed.
 * Facets: Probably the best way to achieve this is to write a geometry that
   creates appropriate Plot objects, renders them and squishes them together.
   There will also no doubt need to be some special casing to make it look good.
 * Document things. This will eventually be a large project, anyway.
 * Equations in text. jsMath is one possibility, but that would break my
   "coherent without javascript" rule. A better option might be optionally
   requiring latex plus whatever is needed to convert latex output to svg.
 * Scales based on time.
 * Rendering and embedding raster graphics. If a plot has many thousands of data
   points, there should be a way to make part of the plot a bitmap. If the cairo
   backend is maintained this should actually be pretty easy: render part of the
   plot to a png, then base 64 encode the png data and embed it in the svg.
 * Embed output from other programs. For example, graphviz. This also might be
   the easiest way to go about providing some support for 3d plots (that is,
   punting to gnuplot, asymptote, or the like).
 * Automated testing. Make a bunch of example plots and write a program that
   compares output to a reference render (or just compares output between two
   git commits). This has to be able to disregard cosmetic differences in the
   svg, so the best bet is to generate svg, convert it to bitmap (with librsvg
   maybe) and compare bitmaps.

Experimental/long-term projects:
 * What are ways we can encourage people to properly label the axis on their
   plots? Are there simple rules we can use that would trigger warnings when
   the default axis labels (i.e. column names) are poor?
 * Would a table geometry be worthwhile? Are there ways tables and plots could
   be combined, possibly along the lines of Tufte's spark lines?
 * Prior to calling `draw`, there is no knowledge of the the size in absolute
   units of the plot. If we were to know this in advance it might allow us to
   try to fit text into the alloted size by rotating labels and word-wrapping.
   Is there a reasonable interface where the final plot size could be optionally
   supplied?


