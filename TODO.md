
Small/Medium projects:
 * Currently the default instance of an element is lowercase (e.g. `Geom.bar`),
   and any non-default instance in constructed with the type name
   (e.g. `Geom.BarGeometry`). This is dumb. Make the `Geom.bar` name work in
   both contexts.
 * Something like `geom_crossbar`.
 * Geom.hexbin
 * Something equivalent to xlim/ylim in ggplot2.
 * Handle NaN and Inf gracefully. NaN should be filtered out it most cases. We
   could handle Inf/-Inf like ggplot2 does by placing points at the very edge of
   the plot, but this can be misleading. Maybe filtering them and issuing a
   warning is better.
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
 * Write a function that examines a plot (rendered or otherwise) and reports
   the minimum size needed to render it such that no labels overlap.
 * Write up a style guide for julia code in compose/gadfly.

Large projects:
 * More interaction by serializing plots and sending them back and forth between
   julia an a browser-based plot viewer. TODO still:
       * Make `webshow` run in tho background, so the repl is still usable.
       * Indicate in the browser when the client in still waiting for a
         response. (A loading widget of some sort.)
       * Some way of editing the json representation that isn't totally
         worthless.
       * Make axis lables editable by clicking on them?
 * Intigration into ipython.
 * Come up with a documentation standard and apply it. Something along the line
   of: one .md file for every exported symbol. Then implement a help function
   that prints these prettily.
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

Experimental/long-term projects:
 * What are ways we can encourage people to properly label the axis on their
   plots? Are there simple rules we can use that would trigger warnings when
   the default axis labels (i.e. column names) are poor?
 * Would a table geometry be worthwhile? Are there ways tables and plots could
   be combined, possibly along the lines of Tufte's spark lines?


