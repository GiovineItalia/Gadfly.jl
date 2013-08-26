
Small/Medium projects:
 * Write a function that examines a plot (rendered or otherwise) and reports
   the minimum size needed to render it such that no labels overlap.
   Complain when forced to draw a plot at a size that might cause overlapping.
   Suggest a better size.
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
 * Write up a style guide for julia code in compose/gadfly.
 * Make generated javascript more readable.

Large projects:
 * More interaction by serializing plots and sending them back and forth between
   julia and a browser-based plot viewer. TODO still:
       * Make `webshow` run in tho background, so the repl is still usable.
       * Indicate in the browser when the client in still waiting for a
         response. (A loading widget of some sort.)
       * Some way of editing the json representation that isn't totally
         worthless.
       * Make axis lables editable by clicking on them?
 * Equations in text. jsMath is one possibility, but that would break my
   "coherent without javascript" rule. A better option might be optionally
   requiring latex plus whatever is needed to convert latex output to svg.
 * Scales based on time. Find some good specimens.
 * Rendering and embedding raster graphics. If a plot has many thousands of data
   points, there should be a way to make part of the plot a bitmap. If the cairo
   backend is maintained this should actually be pretty easy: render part of the
   plot to a png, then base 64 encode the png data and embed it in the svg.

Experimental/long-term projects:
 * Would a table geometry be worthwhile? Are there ways tables and plots could
   be combined, possibly along the lines of Tufte's spark lines?


