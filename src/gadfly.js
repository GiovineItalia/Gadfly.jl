
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
    })
}


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
}

var guide_background_mouseout = function(color) {
    return (function () {
        d3.selectAll(".xgridlines, .ygridlines")
          .transition()
          .duration(250)
          .attr("stroke", color);
    });
}


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
}




var drag_behavior = function(t) {
    return d3.behavior.drag()
      .on("drag", function(d, i) {
        t.x += d3.event.dx;
        t.y += d3.event.dy;

        d3.selectAll(".geometry")
          .attr("transform", function() {
              return "translate(" + [t.x, t.y] + ")";
          });

          d3.selectAll(".xgridlines,.xlabels")
            .attr("transform", function() {
                return "translate(" + [t.x, 0.0] + ")";
            });

          d3.selectAll(".ygridlines,.ylabels")
            .attr("transform", function() {
                return "translate(" + [0.0, t.y] + ")";
            });


        // TODO:
        // Gridlines: we need to handle x and y gridlines differently.
        // Or, maybe this is a dead end.
        // Eventually we are going to have to figure out how to recompute grid
        // lines.
    });
}

