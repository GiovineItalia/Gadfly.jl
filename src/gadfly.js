
// Construct a callback for toggling geometries on/off using color groupings.
//
// Args:
//   colorclass: class names assigned to geometries belonging to a paricular
//               color group.
//
// Returns:
//   A callback function.
//
var guide_toggle_color = function(parent_id, colorclass) {
    var visible = true;
    return (function() {
        if (visible) {
            d3.select(this)
              .transition()
              .duration(250)
              .style("opacity", 0.5);
            d3.select(parent_id)
              .selectAll(".geometry." + colorclass)
              .transition()
              .duration(250)
              .style("opacity", 0);
            visible = false;
        } else {
            d3.select(this)
              .transition()
              .duration(250)
              .style("opacity", 1.0);
            d3.select(parent_id)
              .selectAll(".geometry." + colorclass)
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
var guide_background_mouseover = function(parent_id, color) {
    return (function () {
        d3.select(parent_id)
          .selectAll(".xgridlines, .ygridlines")
          .transition()
          .duration(250)
          .attr("stroke", color);
    });
};

var guide_background_mouseout = function(parent_id, color) {
    return (function () {
        d3.select(parent_id)
          .selectAll(".xgridlines, .ygridlines")
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
//   parent_id: Id of the parent element containing the svg element.
//   t: A transform of the form {"scale": scale}
//   old_scale: The scaling factor applied prior to t.scale.
//
var set_geometry_transform = function(parent_id, t, old_scale) {
    // transform geometries
    d3.select(parent_id)
      .selectAll(".geometry")
      .attr("transform", function() {
          return "translate(" + [t.x, t.y] + ") " +
                 "scale(" + t.scale + ")";
      });

    // unscale geometry widths, radiuses, etc.
    var size_attribs = ["r"];
    d3.select(parent_id)
      .selectAll(".geometry")
      .each(function() {
          this_selection = d3.select(this);
          for (var i in size_attribs) {
              var attrib = size_attribs[i];
              this_selection.attr(attrib,
                  old_scale / t.scale * this_selection.attr(attrib));
          }
      });

    // TODO:
    // Is this going to work when we do things other than circles. Suppose we
    // have plots where we have a path drawing some sort of symbol which we want
    // to remain size-invariant. Should we be trying to place things using
    // translate?

    // transform gridlines
    d3.select(parent_id)
      .selectAll(".xgridlines")
      .attr("transform", function() {
        return "translate(" + [t.x, 0.0] + ") " +
               "scale(" + [t.scale, 1.0] + ")";
      });

      d3.select(parent_id)
        .selectAll(".ygridlines")
        .attr("transform", function() {
          return "translate(" + [0.0, t.y] + ") " +
                 "scale(" + [1.0, t.scale] + ")";
      });

    // unscale gridline widths
    d3.select(parent_id)
      .selectAll(".xgridlines,.ygridlines")
      .each(function() {
          d3.select(this).attr("stroke-width",
              old_scale / t.scale * d3.select(this).attr("stroke-width"));
      });

    // move labels around
    d3.select(parent_id)
      .selectAll(".xlabels")
      .attr("transform", function() {
          return "translate(" + [t.x, 0.0] + ")";
      })
      .selectAll("text")
        .each(function() {
            d3.select(this).attr("x",
                t.scale / old_scale * d3.select(this).attr("x"));
        });

    d3.select(parent_id)
      .selectAll(".ylabels")
      .attr("transform", function() {
          return "translate(" + [0.0, t.y] + ")";
      })
      .selectAll("text")
        .each(function() {
            d3.select(this).attr("y",
                t.scale / old_scale * d3.select(this).attr("y"));
        });
};


// Construct a callback used for zoombehavior.
//
// Args:
//   parent_id: Id of the parent element containing the svg element.
//   t: A transform of the form {"scale": scale} to close arround.
//
// Returns:
//   A zoom behavior.
//
var zoom_behavior = function(parent_id, t) {
    var zm = d3.behavior.zoom();
    zm.scaleExtent([1.0/3.0, 10.0])
      .on("zoom", function(d, i) {
        old_scale = t.scale;
        t.scale = d3.event.scale;
        var bbox = d3.select(parent_id)
                     .select(".guide.background")
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
            parent_id,
            {"x": tx,
             "y": ty,
             "scale": t.scale}, old_scale);
        zm.translate([tx, ty]);
    });
    return zm;
};


