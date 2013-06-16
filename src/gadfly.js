
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
        if (visible) {
            d3.select(this)
              .transition()
              .duration(250)
              .style("opacity", 0.5);
            d3.selectAll(".geometry." + colorclass)
              .transition()
              .duration(250)
              .style("opacity", 0);
            visible = false;
        } else {
            d3.select(this)
              .transition()
              .duration(250)
              .style("opacity", 1.0);
            d3.selectAll(".geometry." + colorclass)
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
        d3.selectAll(".xgridlines, .ygridlines")
          .transition()
          .duration(250)
          .attr("stroke", color);
    });
};

var guide_background_mouseout = function(color) {
    return (function () {
        d3.selectAll(".xgridlines, .ygridlines")
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
//   t: A transform of the form {"x": x, "y": y, "scale": scale}
//   old_scale: The scaling factor applied prior to t.scale.
//
var set_geometry_transform = function(t, old_scale) {
    // transform geometries
    d3.selectAll(".geometry")
      .attr("transform", function() {
          return "translate(" + [t.x, t.y] + ") " +
                 "scale(" + t.scale + ")";
      });

    // unscale geometry widths, radiuses, etc.
    var size_attribs = ["r", "font-size"];
    d3.selectAll(".geometry")
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
    d3.selectAll(".xgridlines")
      .attr("transform", function() {
        return "translate(" + [t.x, 0.0] + ") " +
               "scale(" + [t.scale, 1.0] + ")";
      });

    d3.selectAll(".ygridlines")
      .attr("transform", function() {
          return "translate(" + [0.0, t.y] + ") " +
                 "scale(" + [1.0, t.scale] + ")";
      });

    // unscale gridline widths
    d3.selectAll(".xgridlines,.ygridlines")
      .each(function() {
          d3.select(this).attr("stroke-width",
              old_scale / t.scale * d3.select(this).attr("stroke-width"));
      });

    // move labels around
    d3.selectAll(".xlabels")
      .attr("transform", function() {
          return "translate(" + [t.x, 0.0] + ")";
      })
      .selectAll("text")
        .each(function() {
            d3.select(this).attr("x",
                t.scale / old_scale * d3.select(this).attr("x"));
        });

    d3.selectAll(".ylabels")
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
//   t: A transform of the form {"x": x, "y": x, "scale": scale} to close arround.
//
// Returns:
//   A zoom behavior.
//
var zoom_behavior = function(t) {
    //var bbox = d3.select(".guide.background").select("path").node().getBBox();
    return d3.behavior.zoom()
      .on("zoom", function(d, i) {
        old_scale = t.scale;
        t.scale = d3.event.scale;
        //set_geometry_transform(t, old_scale);
        set_geometry_transform(
            {"x": d3.event.translate[0],
             "y": d3.event.translate[1],
             "scale": t.scale}, old_scale);
    });
};


