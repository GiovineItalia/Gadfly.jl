

// Minimum and maximum scale extents
var MIN_SCALE = 1.0/3.0;
var MAX_SCALE = 10.0;


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

        root.selectAll(".zoomslider")
            .transition()
            .duration(250)
            .attr("opacity", 1.0);
    });
};

var guide_background_mouseout = function(color) {
    return (function () {
        var root = getplotroot(d3.select(this));
        root.selectAll(".xgridlines, .ygridlines")
            .transition()
            .duration(250)
            .attr("stroke", color);

        root.selectAll(".zoomslider")
            .transition()
            .duration(250)
            .attr("opacity", 0.0);
    });
};


// Construct a call back used for mouseover effects in the point geometry.
//
// Args:
//   scale: Scale for expanded width
//   ratio: radius / line-width. This is necessary to maintain relative width
//          at arbitraty levels of zoom
//
// Returns:
//  Callback function.
//
var geom_point_mouseover = function(scale, ratio) {
    return (function() {
        var lw = this.getAttribute('r') * ratio * scale
        d3.select(this)
          .transition()
          .duration(100)
          .style("stroke-width", lw + 'px', 'important');
    });
};

// Construct a call back used for mouseout effects in the point geometry.
//
// Args:
//   scale: Scale for expanded width
//   ratio: radius / line-width. This is necessary to maintain relative width
//          at arbitraty levels of zoom
//
// Returns:
//  Callback function.
//
var geom_point_mouseout = function(scale, ratio) {
    return (function() {
        var lw = this.getAttribute('r') * ratio
        d3.select(this)
          .transition()
          .duration(100)
          .style("stroke-width", lw + 'px', 'important');
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
var set_geometry_transform = function(root, ctx, old_scale) {
    var xscalable = root.node().classList.contains("xscalable");
    var yscalable = root.node().classList.contains("yscalable");

    var xscale = 1.0;
    var tx = 0.0;
    if (xscalable) {
        xscale = ctx.scale;
        tx = ctx.tx;
    }

    var yscale = 1.0;
    var ty = 0.0;
    if (yscalable) {
        yscale = ctx.scale;
        ty = ctx.ty;
    }

    root.selectAll(".geometry")
        .attr("transform",
          "translate(" + tx + " " + ty + ") " +
              "scale(" + xscale + " " + yscale + ")");

    var unscale_factor = old_scale / ctx.scale;

    // unscale geometry widths, radiuses, etc.
    var size_attribs = ["r"];
    var size_styles = ["font-size", "stroke-width"];
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
                return "translate(" + [ctx.tx, 0.0] + ") " +
                       "scale(" + [ctx.scale, 1.0] + ")";
          });

        root.selectAll(".xlabels")
            .attr("transform", function() {
              return "translate(" + [ctx.tx, 0.0] + ")";
          })
          .selectAll("text")
            .each(function() {
                d3.select(this).attr("x",
                    ctx.scale / old_scale * d3.select(this).attr("x"));
            });
    }

    if (yscalable) {
        root.selectAll(".xfixed")
            .attr("transform", function() {
              return "translate(" + [0.0, ctx.ty] + ") " +
                     "scale(" + [1.0, ctx.scale] + ")";
            });

        root.selectAll(".ylabels")
            .attr("transform", function() {
              return "translate(" + [0.0, ctx.ty] + ")";
            })
            .selectAll("text")
              .each(function() {
                  d3.select(this).attr("y",
                      ctx.scale / old_scale * d3.select(this).attr("y"));
            });
    }

    var bbox = root.select(".guide.background")
                   .select("path").node().getBBox();

    // hide/show ticks labels based on their position
    root.selectAll(".xlabels")
        .selectAll("text")
        .attr("visibility", function() {
            var x = parseInt(d3.select(this).attr("x"), 10) + ctx.tx;
            return bbox.x <= x && x <= bbox.x + bbox.width ? "visible" : "hidden";
        });

    root.selectAll(".ylabels")
        .selectAll("text")
        .attr("visibility", function() {
            var y = parseInt(d3.select(this).attr("y"), 10) + ctx.ty;
            return bbox.y <= y && y <= bbox.y + bbox.height ? "visible" : "hidden";
        });
};


// Construct a callback used for zoombehavior.
//
// Args:
//   t: A transform of the form {"scale": scale} to close arround.
//
// Returns:
//   A zoom behavior.
//
var zoom_behavior = function(ctx) {
    var zm = d3.behavior.zoom();
    ctx.zoom_behavior = zm;

    zm.scaleExtent([MIN_SCALE, MAX_SCALE])
      .on("zoom", function(d, i) {
        var root = getplotroot(d3.select(this));
        old_scale = ctx.scale;
        ctx.scale = d3.event.scale;
        var bbox = root.select(".guide.background")
                       .select("path").node().getBBox();

        var x_min = -bbox.width * ctx.scale - (ctx.scale * bbox.width - bbox.width);
        var x_max = bbox.width * ctx.scale;
        var y_min = -bbox.height * ctx.scale - (ctx.scale * bbox.height - bbox.height);
        var y_max = bbox.height * ctx.scale;

        var x0 = bbox.x - ctx.scale * bbox.x;
        var y0 = bbox.y - ctx.scale * bbox.y;

        var tx = Math.max(Math.min(d3.event.translate[0] - x0, x_max), x_min);
        var ty = Math.max(Math.min(d3.event.translate[1] - y0, y_max), y_min);

        tx += x0;
        ty += y0;

        ctx.tx = tx;
        ctx.ty = ty;

        set_geometry_transform(
            root,
            {"tx": tx,
             "ty": ty,
             "scale": ctx.scale}, old_scale);
        zm.translate([tx, ty]);

        update_zoomslider(root, ctx);
      });


    return (function (g) {
        zm(g);
        default_handler = g.on("wheel.zoom");
        function wheelhandler() {
        if (d3.event.shiftKey) {
                default_handler.call(this);
                d3.event.stopPropagation();
            }
        }
        g.on("wheel.zoom", wheelhandler)
         .on("mousewheel.zoom", wheelhandler)
         .on("DOMMouseScroll.zoom", wheelhandler);
    });
};


var slider_position_from_scale = function(scale) {
    if (scale >= 1.0) {
        return 0.5 + 0.5 * (Math.log(scale) / Math.log(MAX_SCALE));
    }
    else {
        return 0.5 * (Math.log(scale) - Math.log(MIN_SCALE)) / (0 - Math.log(MIN_SCALE));
    }
};


// Construct a call
var zoomslider_behavior = function(ctx, min_extent, max_extent) {
    var drag = d3.behavior.drag();
    ctx.zoomslider_behavior = drag;
    ctx.min_zoomslider_extent = min_extent;
    ctx.max_zoomslider_extent = max_extent;

    drag.on("drag", function() {
        var xmid = (min_extent + max_extent) / 2;
        var new_scale;

        // current slider posisition
        var xpos = slider_position_from_scale(ctx.scale) +
            (d3.event.dx / (max_extent - min_extent));

        // new scale
        if (xpos >= 0.5) {
            new_scale = Math.exp(2.0 * (xpos - 0.5) * Math.log(MAX_SCALE));
        }
        else {
            new_scale = Math.exp(2.0 * xpos * (0 - Math.log(MIN_SCALE)) +
                Math.log(MIN_SCALE));
        }
        new_scale = Math.min(MAX_SCALE, Math.max(MIN_SCALE, new_scale));

        // update scale
        var root = getplotroot(d3.select(this));
        var new_trans = scale_centered_translation(root, ctx, new_scale);

        ctx.zoom_behavior.scale(new_scale);
        ctx.zoom_behavior.translate(new_trans);
        ctx.zoom_behavior.event(root);

        // Note: the zoom event will take care of repositioning the slider thumb
    });

    drag.on("dragstart", function() {
        d3.event.sourceEvent.stopPropagation();
    });

    return drag;
};


// Reposition the zoom slider thumb based on the current scale
var update_zoomslider = function(root, ctx) {
    var xmid = (ctx.min_zoomslider_extent + ctx.max_zoomslider_extent) / 2;
    var xpos = ctx.min_zoomslider_extent +
        ((ctx.max_zoomslider_extent - ctx.min_zoomslider_extent) *
            slider_position_from_scale(ctx.scale));
    root.select(".zoomslider_thumb")
        .attr("transform", "translate(" + (xpos - xmid) + " " + 0 + ")");
};


// Compute the translation needed to change the scale when keeping the plot
// centered.
scale_centered_translation = function(root, ctx, new_scale) {
    var bbox = root.select(".guide.background")
                   .select("path").node().getBBox();

    // how off from center the current view is
    var xoff = ctx.zoom_behavior.translate()[0] -
              (bbox.x * (1 - ctx.scale) + (bbox.width * (1 - ctx.scale)) / 2);
    var yoff = ctx.zoom_behavior.translate()[1] -
              (bbox.y * (1 - ctx.scale) + (bbox.height * (1 - ctx.scale)) / 2);

    // rescale offsets
    xoff = xoff * new_scale / ctx.scale;
    yoff = yoff * new_scale / ctx.scale;

    // adjust for the panel position being scaled
    var x_edge_adjust = bbox.x * (1 - new_scale);
    var y_edge_adjust = bbox.y * (1 - new_scale);

    return [xoff + x_edge_adjust + (bbox.width - bbox.width * new_scale) / 2,
            yoff + y_edge_adjust + (bbox.height - bbox.height * new_scale) / 2];
};


// jump to a new scale with a nice transition
var zoom_step = function(root, ctx, new_scale) {
    var bbox = root.select(".guide.background")
                   .select("path").node().getBBox();
    ctx.zoom_behavior.size([bbox.width, bbox.height]);
    new_trans = scale_centered_translation(root, ctx, new_scale);

    root.transition()
        .duration(250)
        .tween("zoom", function()  {
            var trans_interp = d3.interpolate(ctx.zoom_behavior.translate(), new_trans);
            var scale_interp = d3.interpolate(ctx.zoom_behavior.scale(), new_scale);
            return function (t) {
                ctx.zoom_behavior.translate(trans_interp(t))
                                 .scale(scale_interp(t));
                ctx.zoom_behavior.event(root);
            };
        });
};


// Handlers for clicking the zoom in or zoom out buttons.
var zoomout_behavior = function(ctx) {
    return (function() {
        var new_scale = Math.max(MIN_SCALE, ctx.scale / 1.5);
        var root = getplotroot(d3.select(this));
        zoom_step(root, ctx, new_scale);
        d3.event.stopPropagation();
    });
};


var zoomin_behavior = function(ctx) {
    return (function() {
        var new_scale = Math.min(MAX_SCALE, ctx.scale * 1.5);
        var root = getplotroot(d3.select(this));
        zoom_step(root, ctx, new_scale);
        d3.event.stopPropagation();
    });
};


var zoomslider_track_behavior = function(ctx, min_extent, max_extent) {
    return (function() {
        var xpos = slider_position_from_scale(ctx.scale);
        var bbox = this.getBBox();
        var xclick = (d3.mouse(this)[0] - bbox.x) / bbox.width;
        var root = getplotroot(d3.select(this));
        var new_scale;
        if (xclick < xpos) {
            new_scale = Math.max(MIN_SCALE, ctx.scale / 1.5);
            zoom_step(root, ctx, new_scale);
        }
        else {
            new_scale = Math.min(MAX_SCALE, ctx.scale * 1.5);
            zoom_step(root, ctx, new_scale);
        }
        d3.event.stopPropagation();
    });
};


// Mouseover effects for zoom slider
var zoomslider_button_mouseover = function(destcolor) {
    return (function() {
        d3.select(this)
          .selectAll(".button_logo")
          .transition()
          .duration(150)
          .attr("fill", destcolor);
    });
};


var zoomslider_thumb_mouseover = function(destcolor) {
    return (function() {
        d3.select(this)
          .transition()
          .duration(150)
          .attr("fill", destcolor);
    });
};

//@ sourceURL=gadfly.js
