

// Traverse upwards from a d3 selection to find and return the first
// node with "plotroot" class.
var getplotroot = function(selection)  {
    var node = selection.node();
    while (node && node.classList && !node.classList.contains("plotroot")) {
        node = node.parentNode;
    }
    return d3.select(node);
};


// Construct a callback for toggling geometries on/off using color groupings.
//
// Args:
//   colorclass: class names assigned to geometries belonging to a paricular
//               color group.
//
// Returns:
//   A callback function.
//
var guide_toggle_color = function(colorclass) {
    var visible = true;
    return (function() {
        var root = getplotroot(d3.select(this));
        if (visible) {
            d3.select(this)
              .transition()
              .duration(250)
              .style("opacity", 0.5);
            root.selectAll(".geometry." + colorclass)
                .transition()
                .duration(250)
                .style("opacity", 0);
            visible = false;
        } else {
            d3.select(this)
              .transition()
              .duration(250)
              .style("opacity", 1.0);
            root.selectAll(".geometry." + colorclass)
                .transition()
                .duration(250)
                .style("opacity", 1.0);
            visible = true;
        }
    });
};


// Construct a callback used to toggle highly-visibility grid lines.
//
// Args:
//   color: Faded-in/faded-out color, respectively.
//
// Returns:
//   Callback function.
//
var guide_background_mouseover = function(color) {
    return (function () {
        var root = getplotroot(d3.select(this));
        root.selectAll(".xgridlines, .ygridlines")
            .transition()
            .duration(250)
            .attr("stroke", color);
    });
};

var guide_background_mouseout = function(color) {
    return (function () {
        var root = getplotroot(d3.select(this));
        root.selectAll(".xgridlines, .ygridlines")
            .transition()
            .duration(250)
            .attr("stroke", color);
    });
};


// Construct a call back used for mouseover effects in the point geometry.
//
// Args:
//   lw: Stroke width to transition to.
//
// Returns:
//  Callback function.
//
var geom_point_mouseover = function(lw) {
    return (function() {
        d3.select(this)
          .transition()
          .duration(100)
          .attr("stroke-width", lw);
    });
};


// Translate and scale geometry while trying to maintain scale invariance for
// certain ellements.
//
// Args:
//   root: d3 selection of the root plot group node.
//   t: A transform of the form {"scale": scale}
//   old_scale: The scaling factor applied prior to t.scale.
//
var set_geometry_transform = function(root, t, old_scale) {
    var xscalable = root.node().classList.contains("xscalable");
    var yscalable = root.node().classList.contains("yscalable");

    var xscale = 1.0;
    var tx = 0.0;
    if (xscalable) {
        xscale = t.scale;
        tx = t.x;
    }

    var yscale = 1.0;
    var ty = 0.0;
    if (yscalable) {
        yscale = t.scale;
        ty = t.y;
    }

    root.selectAll(".geometry")
        .attr("transform", function() {
          return "translate(" + [tx, ty] + ") " +
                 "scale(" + xscale + "," + yscale + ")";
      });

    var unscale_factor = old_scale / t.scale;

    // unscale geometry widths, radiuses, etc.
    var size_attribs = ["r"];
    var size_styles = ["font-size"];
    root.select(".plotpanel")
        .selectAll("g, .geometry")
        .each(function() {
          sel = d3.select(this);
          var i;
          var key;
          var val;
          for (i in size_styles) {
              key = size_styles[i];
              val = sel.style(key);
              if (val !== null) {
                  // For some reason d3 rounds things like font-sizes to the
                  // nearest integer, so we are setting styles directly instead.
                  val = parseFloat(val);
                  sel.node().style.setProperty(key, unscale_factor * val + "px", "important");
              }
          }

          for (i in size_attribs) {
              key = size_attribs[i];
              val = sel.attr(key);
              if (val !== null) {
                  sel.attr(key, unscale_factor * val);
              }
          }
      });

    // TODO:
    // Is this going to work when we do things other than circles. Suppose we
    // have plots where we have a path drawing some sort of symbol which we want
    // to remain size-invariant. Should we be trying to place things using
    // translate?

    // move axis labels and grid lines around
    if (xscalable) {
        root.selectAll(".yfixed")
            .attr("transform", function() {
                return "translate(" + [t.x, 0.0] + ") " +
                       "scale(" + [t.scale, 1.0] + ")";
          });

        root.selectAll(".xlabels")
            .attr("transform", function() {
              return "translate(" + [t.x, 0.0] + ")";
          })
          .selectAll("text")
            .each(function() {
                d3.select(this).attr("x",
                    t.scale / old_scale * d3.select(this).attr("x"));
            });
    }

    if (yscalable) {
        root.selectAll(".xfixed")
            .attr("transform", function() {
              return "translate(" + [0.0, t.y] + ") " +
                     "scale(" + [1.0, t.scale] + ")";
            });

        root.selectAll(".ylabels")
            .attr("transform", function() {
              return "translate(" + [0.0, t.y] + ")";
            })
            .selectAll("text")
              .each(function() {
                  d3.select(this).attr("y",
                      t.scale / old_scale * d3.select(this).attr("y"));
            });
    }
};


// Construct a callback used for zoombehavior.
//
// Args:
//   t: A transform of the form {"scale": scale} to close arround.
//
// Returns:
//   A zoom behavior.
//
var zoom_behavior = function(t) {
    var zm = d3.behavior.zoom();
    zm.scaleExtent([1.0/3.0, 10.0])
      .on("zoom", function(d, i) {
        var root = getplotroot(d3.select(this));
        old_scale = t.scale;
        t.scale = d3.event.scale;
        var bbox = root.select(".guide.background")
                       .select("path").node().getBBox();

        var x_min = -bbox.width * t.scale - (t.scale * bbox.width - bbox.width);
        var x_max = bbox.width * t.scale;
        var y_min = -bbox.height * t.scale - (t.scale * bbox.height - bbox.height);
        var y_max = bbox.height * t.scale;

        var x0 = bbox.x - t.scale * bbox.x;
        var y0 = bbox.y - t.scale * bbox.y;

        var tx = Math.max(Math.min(d3.event.translate[0] - x0, x_max), x_min);
        var ty = Math.max(Math.min(d3.event.translate[1] - y0, y_max), y_min);

        tx += x0;
        ty += y0;

        set_geometry_transform(
            root,
            {"x": tx,
             "y": ty,
             "scale": t.scale}, old_scale);
        zm.translate([tx, ty]);
    });
    return zm;
};


