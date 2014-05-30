

// Convert an offset in screen units (pixels) to client units (millimeters)
var client_offset = function(fig, x, y) {
    var client_box = fig.node.getBoundingClientRect();
    x = x * fig.node.viewBox.baseVal.width / client_box.width;
    y = y * fig.node.viewBox.baseVal.height / client_box.height;
    return [x, y]
};


// Get an x/y coordinate value in pixels
var xPX = function(fig, x) {
    var client_box = fig.node.getBoundingClientRect();
    return x * fig.node.viewBox.baseVal.width / client_box.width;
};

var yPX = function(fig, y) {
    var client_box = fig.node.getBoundingClientRect();
    return y * fig.node.viewBox.baseVal.height / client_box.height;
};


Snap.plugin(function (Snap, Element, Paper, global) {
    // Traverse upwards from a snap element to find and return the first
    // note with the "plotroot" class.
    Element.prototype.plotroot = function () {
        var element = this;
        while (!element.hasClass("plotroot") && element.parent() != null) {
            element = element.parent();
        }
        return element;
    };

    Element.prototype.plotbounds = function () {
        var root = this.plotroot()
        var bbox = root.select(".guide.background").node.getBBox();
        return {
            x0: bbox.x,
            x1: bbox.x + bbox.width,
            y0: bbox.y,
            y1: bbox.y + bbox.height
        };
    };

    Element.prototype.plotcenter = function () {
        var root = this.plotroot()
        var bbox = root.select(".guide.background").node.getBBox();
        return {
            x: bbox.x + bbox.width / 2,
            y: bbox.y + bbox.height / 2
        };
    };

    // Emulate IE style mouseenter/mouseleave events, since Microsoft always
    // does everything right.
    // See: http://www.dynamic-tools.net/toolbox/isMouseLeaveOrEnter/
    var events = ["mouseenter", "mouseleave"];

    for (i in events) {
        (function (event_name) {
            var event_name = events[i];
            Element.prototype[event_name] = function (fn, scope) {
                if (Snap.is(fn, "function")) {
                    var fn2 = function (event) {
                        if (event.type != "mouseover" && event.type != "mouseout") {
                            return;
                        }

                        var reltg = event.relatedTarget ? event.relatedTarget :
                            event.type == "mouseout" ? event.toElement : event.fromElement;
                        while (reltg && reltg != this.node) reltg = reltg.parentNode;

                        if (reltg != this.node) {
                            return fn.apply(this, event);
                        }
                    };

                    if (event_name == "mouseenter") {
                        this.mouseover(fn2, scope);
                    } else {
                        this.mouseout(fn2, scope);
                    }
                }
                return this;
            };
        })(events[i]);
    }
});


// When the plot is moused over, emphasize the grid lines.
var plot_mouseover = function(event) {
    var root = this.plotroot();

    // emphasize grid lines
    var destcolor = root.data("focused_xgrid_color");
     root.select(".xgridlines")
         .selectAll("path")
         .animate({stroke: destcolor}, 250);

    destcolor = root.data("focused_ygrid_color");
     root.select(".ygridlines")
         .selectAll("path")
         .animate({stroke: destcolor}, 250);

    // reveal zoom slider
    root.select(".zoomslider")
        .animate({opacity: 1.0}, 250);
};


// Unemphasize grid lines on mouse out.
var plot_mouseout = function(event) {
    var root = this.plotroot();
    var destcolor = root.data("unfocused_xgrid_color");
     root.select(".xgridlines")
         .selectAll("path")
         .animate({stroke: destcolor}, 250);

    destcolor = root.data("unfocused_ygrid_color");
     root.select(".ygridlines")
         .selectAll("path")
         .animate({stroke: destcolor}, 250);

    // hide zoom slider
     root.select(".zoomslider")
         .animate({opacity: 0.0}, 250);
};


var set_geometry_transform = function(root, tx, ty, scale) {
    var xscalable = root.hasClass("xscalable"),
        yscalable = root.hasClass("yscalable");

    var old_scale = root.data("scale");

    var xscale = xscalable ? scale : 1.0,
        yscale = yscalable ? scale : 1.0;

    tx = xscalable ? tx : 0.0;
    ty = yscalable ? ty : 0.0;

    var t = new Snap.Matrix().translate(tx, ty).scale(xscale, yscale);

    root.selectAll(".geometry")
        .forEach(function (element, i) {
            element.transform(t);
        });

    bounds = root.plotbounds();

    if (yscalable) {
        var xfixed_t = new Snap.Matrix().translate(0, ty).scale(1.0, yscale);
        var ytrans = new Snap.Matrix().translate(0, ty);
        root.selectAll(".xfixed")
            .forEach(function (element, i) {
                element.transform(xfixed_t);
            });

        root.select(".ylabels")
            .transform(ytrans)
            .selectAll("text")
            .forEach(function (element, i) {
                var y = element.attr("y") * scale / old_scale;
                element.attr("y", y);

                if (element.attr("gadfly:inscale") == "true") {
                    y += ty;
                    element.attr("visibility",
                        bounds.y0 <= y && y <= bounds.y1 ? "visible" : "hidden");
                }
            });
    }

    if (xscalable) {
        var yfixed_t = new Snap.Matrix().translate(tx, 0).scale(xscale, 1.0);
        var xtrans = new Snap.Matrix().translate(tx, 0);
        root.selectAll(".yfixed")
            .forEach(function (element, i) {
                element.transform(yfixed_t);
            });

        root.select(".xlabels")
            .transform(xtrans)
            .selectAll("text")
            .forEach(function (element, i) {
                var x = element.attr("x") * scale / old_scale;
                element.attr("x", x);

                if (element.attr("gadfly:inscale") == "true") {
                    x += tx;
                    element.attr("visibility",
                        bounds.x0 <= x && x <= bounds.x1 ? "visible" : "hidden");
                }
            });
    }

    // we must unscale anything that is scale invariance: widths, raiduses, etc.
    var size_attribs = ["r", "font-size", "stroke-width"];
    root.selectAll(".geometry > *, .xgridlines, .ygridlines")
        .forEach(function (element, i) {
            for (i in size_attribs) {
                var key = size_attribs[i];
                var val = parseFloat(element.attr(key));
                if (val !== undefined && val != 0 && !isNaN(val)) {
                    element.attr(key, val * old_scale / scale);
                }
            }
        });
};


// Find the most appropriate tick scale and update label visibility.
var update_tickscale = function(root, scale) {
    var tickscales = root.data("tickscales");
    var best_tickscale = 1.0;
    var best_tickscale_dist = Infinity;
    for (tickscale in tickscales) {
        var dist = Math.abs(Math.log(tickscale) - Math.log(scale));
        if (dist < best_tickscale_dist) {
            best_tickscale_dist = dist;
            best_tickscale = tickscale;
        }
    }

    if (best_tickscale != root.data("tickscale")) {
        root.data("tickscale", best_tickscale);

        var mark_inscale_gridlines = function (element, i) {
            var inscale = element.attr("gadfly:scale") == best_tickscale;
            element.attr("gadfly:inscale", inscale);
            element.attr("visibility", inscale ? "visible" : "hidden");
        };

        var mark_inscale_labels = function (element, i) {
            var inscale = element.attr("gadfly:scale") == best_tickscale;
            element.attr("gadfly:inscale", inscale);
            element.attr("visibility", inscale ? "visible" : "hidden");
        };

        root.select(".xgridlines").selectAll("path").forEach(mark_inscale_gridlines);
        root.select(".ygridlines").selectAll("path").forEach(mark_inscale_gridlines);
        root.select(".xlabels").selectAll("text").forEach(mark_inscale_labels);
        root.select(".ylabels").selectAll("text").forEach(mark_inscale_labels);
    }
};


var set_plot_pan_zoom = function(root, tx, ty, scale) {
    var old_scale = root.data("scale");
    var bounds = root.plotbounds();

    var width = bounds.x1 - bounds.x0,
        height = bounds.y1 - bounds.y0;

    // compute the viewport derived from tx, ty, and scale
    var x_min = -width * scale - (scale * width - width),
        x_max = width * scale,
        y_min = -height * scale - (scale * height - height),
        y_max = height * scale;

    var x0 = bounds.x0 - scale * bounds.x0,
        y0 = bounds.y0 - scale * bounds.y0;

    var tx = Math.max(Math.min(tx - x0, x_max), x_min),
        ty = Math.max(Math.min(ty - y0, y_max), y_min);

    tx += x0;
    ty += y0;

    // when the scale change, we may need to alter which set of
    // ticks is being displayed
    if (scale != old_scale) {
        update_tickscale(root, scale);
    }

    set_geometry_transform(root, tx, ty, scale);

    root.data("scale", scale);
    root.data("tx", tx);
    root.data("ty", ty);
};


var scale_centered_translation = function(root, scale) {
    var bounds = root.plotbounds();

    var width = bounds.x1 - bounds.x0,
        height = bounds.y1 - bounds.y0;

    var tx0 = root.data("tx"),
        ty0 = root.data("ty");

    var scale0 = root.data("scale");

    // how off from center the current view is
    var xoff = tx0 - (bounds.x0 * (1 - scale0) + (width * (1 - scale0)) / 2),
        yoff = ty0 - (bounds.y0 * (1 - scale0) + (height * (1 - scale0)) / 2);

    // rescale offsets
    xoff = xoff * scale / scale0;
    yoff = yoff * scale / scale0;

    // adjust for the panel position being scaled
    var x_edge_adjust = bounds.x0 * (1 - scale),
        y_edge_adjust = bounds.y0 * (1 - scale);

    return {
        x: xoff + x_edge_adjust + (width - width * scale) / 2,
        y: yoff + y_edge_adjust + (height - height * scale) / 2
    };
};


// Initialize data for panning zooming if it isn't already.
var init_pan_zoom = function(root) {
    if (root.data("zoompan-ready")) {
        return;
    }

    if (root.data("tx") === undefined) root.data("tx", 0);
    if (root.data("ty") === undefined) root.data("ty", 0);
    if (root.data("scale") === undefined) root.data("scale", 1.0);
    if (root.data("tickscales") === undefined) {

        // index all the tick scales that are listed
        var tickscales = {};
        var add_tick_scales = function (element, i) {
            tickscales[element.attr("gadfly:scale")] = true;
        };

        root.select(".xgridlines").selectAll("path").forEach(add_tick_scales);
        root.select(".ygridlines").selectAll("path").forEach(add_tick_scales);
        root.select(".xlabels").selectAll("text").forEach(add_tick_scales);
        root.select(".ylabels").selectAll("text").forEach(add_tick_scales);

        root.data("tickscales", tickscales);
        root.data("tickscale", 1.0);
    }

    var min_scale = 1.0, max_scale = 1.0;
    for (scale in tickscales) {
        min_scale = Math.min(min_scale, scale);
        max_scale = Math.max(max_scale, scale);
    }
    root.data("min_scale", min_scale);
    root.data("max_scale", max_scale);

    // store the original positions of labels
    root.select(".xlabels")
        .selectAll("text")
        .forEach(function (element, i) {
            element.data("x", element.asPX("x"));
        });

    root.select(".ylabels")
        .selectAll("text")
        .forEach(function (element, i) {
            element.data("y", element.asPX("y"));
        });

    // mark grid lines and ticks as in or out of scale.
    var mark_inscale = function (element, i) {
        element.attr("gadfly:inscale", element.attr("gadfly:scale") == 1.0);
    };

    root.select(".xgridlines").selectAll("path").forEach(mark_inscale);
    root.select(".ygridlines").selectAll("path").forEach(mark_inscale);
    root.select(".xlabels").selectAll("text").forEach(mark_inscale);
    root.select(".ylabels").selectAll("text").forEach(mark_inscale);

    // figure out the upper ond lower bounds on panning using the maximum
    // and minum grid lines
    var bounds = root.plotbounds();
    var pan_bounds = {
        x0: 0.0,
        y0: 0.0,
        x1: 0.0,
        y1: 0.0
    };

    root.select(".xgridlines")
        .selectAll("path")
        .forEach(function (element, i) {
            if (element.attr("gadfly:inscale") == "true") {
                var bbox = element.node.getBBox();
                if (bounds.x1 - bbox.x < pan_bounds.x0) {
                    pan_bounds.x0 = bounds.x1 - bbox.x;
                }
                if (bounds.x0 - bbox.x > pan_bounds.x1) {
                    pan_bounds.x1 = bounds.x0 - bbox.x;
                }
            }
        });

    root.select(".ygridlines")
        .selectAll("path")
        .forEach(function (element, i) {
            if (element.attr("gadfly:inscale") == "true") {
                var bbox = element.node.getBBox();
                if (bounds.y1 - bbox.y < pan_bounds.y0) {
                    pan_bounds.y0 = bounds.y1 - bbox.y;
                }
                if (bounds.y0 - bbox.y > pan_bounds.y1) {
                    pan_bounds.y1 = bounds.y0 - bbox.y;
                }
            }
        });

    // nudge these values a little
    pan_bounds.x0 -= 5;
    pan_bounds.x1 += 5;
    pan_bounds.y0 -= 5;
    pan_bounds.y1 += 5;
    root.data("pan_bounds", pan_bounds);

    // Set all grid lines at scale 1.0 to visible. Out of bounds lines
    // will be clipped.
    root.select(".xgridlines")
        .selectAll("path")
        .forEach(function (element, i) {
            if (element.attr("gadfly:inscale") == "true") {
                element.attr("visibility", "visible");
            }
        });

    root.select(".ygridlines")
        .selectAll("path")
        .forEach(function (element, i) {
            if (element.attr("gadfly:inscale") == "true") {
                element.attr("visibility", "visible");
            }
        });

    root.data("zoompan-ready", true)
};


// Panning
var guide_background_drag_onmove = function(dx, dy, x, y, event) {
    var root = this.plotroot();

    // TODO:
    // This has problems on Firefox. Here's what I think is happening: firefox
    // computes a bounding box for everything, including the invisible shit,
    // which throws off the 'client_offset' calculation.'

    var dxdy = client_offset(fig, dx,  dy);
    dx = dxdy[0];
    dy = dxdy[1];

    var tx0 = root.data("tx"),
        ty0 = root.data("ty");

    var dx0 = root.data("dx"),
        dy0 = root.data("dy");

    root.data("dx", dx);
    root.data("dy", dy);

    dx = dx - dx0;
    dy = dy - dy0;

    var tx = tx0 + dx,
        ty = ty0 + dy;

    set_plot_pan_zoom(root, tx, ty, root.data("scale"));
};


var guide_background_drag_onstart = function(x, y, event) {
    var root = this.plotroot();
    root.data("dx", 0);
    root.data("dy", 0);
    init_pan_zoom(root);
};


var guide_background_drag_onend = function(event) {
    var root = this.plotroot();
};


var zoomslider_button_mouseover = function(event) {
    console.info("zoomslider_button_mouseover");
     this.select(".button_logo")
         .animate({fill: this.data("mouseover_color")}, 100);
};


var zoomslider_button_mouseout = function(event) {
    console.info("zoomslider_button_mouseout");
     this.select(".button_logo")
         .animate({fill: this.data("mouseout_color")}, 100);
};


var zoomslider_zoomout_click = function(event) {
    // TODO
};


var zoomslider_zoomin_click = function(event) {
    // TODO
};


var zoomslider_track_click = function(event) {
    // TODO
};


var zoomslider_thumb_mousedown = function(event) {
    this.animate({fill: this.data("mouseover_color")}, 100);
};


var zoomslider_thumb_mouseup = function(event) {
    this.animate({fill: this.data("mouseout_color")}, 100);
};


// compute the position in [0, 1] of the zoom slider thumb from the current scale
var slider_position_from_scale = function(scale, min_scale, max_scale) {
    if (scale >= 1.0) {
        return 0.5 + 0.5 * (Math.log(scale) / Math.log(max_scale));
    }
    else {
        return 0.5 * (Math.log(scale) - Math.log(min_scale)) / (0 - Math.log(min_scale));
    }
}


var zoomslider_thumb_dragmove = function(dx, dy, x, y) {
    var root = this.plotroot();
    var min_pos = this.data("min_pos"),
        max_pos = this.data("max_pos"),
        min_scale = root.data("min_scale"),
        max_scale = root.data("max_scale"),
        old_scale = root.data("old_scale");

    var dxdy = client_offset(fig, dx,  dy);
    dx = dxdy[0];
    dy = dxdy[1];

    var xmid = (min_pos + max_pos) / 2;
    var xpos = slider_position_from_scale(old_scale, min_scale, max_scale) +
                   dx / (max_pos - min_pos);

    // compute the new scale
    var new_scale;
    if (xpos >= 0.5) {
        new_scale = Math.exp(2.0 * (xpos - 0.5) * Math.log(max_scale));
    }
    else {
        new_scale = Math.exp(2.0 * xpos * (0 - Math.log(min_scale)) +
                        Math.log(min_scale));
    }
    new_scale = Math.min(max_scale, Math.max(min_scale, new_scale));

    var trans = scale_centered_translation(root, new_scale);
    set_plot_pan_zoom(root, trans.x, trans.y, new_scale);

    // TODO: this will have to be move to its own function
    this.transform(new Snap.Matrix().translate(
            Math.max(min_pos, Math.min(
                    max_pos, min_pos + (max_pos - min_pos) * xpos)) - xmid, 0));
};


var zoomslider_thumb_dragstart = function(event) {
    var root = this.plotroot();
    init_pan_zoom(root);

    // keep track of what the scale was when we started dragging
    root.data("old_scale", root.data("scale"));
};


var zoomslider_thumb_dragend = function(event) {
    // TODO
};



//@ sourceURL=gadfly.js
