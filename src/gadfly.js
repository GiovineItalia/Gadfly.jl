
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
            d3.selectAll(".geom." + colorclass)
              .transition()
              .duration(250)
              .style("opacity", 0);
            visible = false;
        } else {
            d3.select(this)
              .transition()
              .duration(250)
              .style("opacity", 1.0);
            d3.selectAll(".geom." + colorclass)
              .transition()
              .duration(250)
              .style("opacity", 1.0);
            visible = true;
        }
    })
}


