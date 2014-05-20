

// Convert an offset in screen units (pixels) to client units (millimeters)
var client_offset = function(fig, x, y) {
    var client_box = fig.node.getBoundingClientRect();
    x = x * fig.node.viewBox.baseVal.width / client_box.width;
    y = y * fig.node.viewBox.baseVal.height / client_box.height;
    return [x, y]
}


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
});


// When the plot is moused over, emphasize the grid lines.
var plot_mouseover = function(event) {
    var root = this.plotroot();
    destcolor = root.data("focused_xgrid_color");
    root.select(".xgridlines")
        .selectAll("path")
        .animate({stroke: destcolor}, 250);

    destcolor = root.data("focused_ygrid_color");
    root.select(".ygridlines")
        .selectAll("path")
        .animate({stroke: destcolor}, 250);
};


// Unemphasize grid lines on mouse out.
var plot_mouseout = function(event) {
    var root = this.plotroot();
    destcolor = root.data("unfocused_xgrid_color");
    root.select(".xgridlines")
        .selectAll("path")
        .animate({stroke: destcolor}, 250);

    destcolor = root.data("unfocused_ygrid_color");
    root.select(".ygridlines")
        .selectAll("path")
        .animate({stroke: destcolor}, 250);
};


// Set a plot's zoom/pan state
var set_plot_pan = function(root, tx, ty) {
    var xscalable = root.hasClass("xscalable");
    var yscalable = root.hasClass("yscalable");

    var t = new Snap.Matrix().translate(tx, ty);
    var xfixed_t = new Snap.Matrix().translate(0, ty);
    var yfixed_t = new Snap.Matrix().translate(tx, 0);

    root.selectAll(".geometry")
        .forEach(function (element, i) {
            element.transform(t);
        });

    bounds = root.plotbounds();

    if (yscalable) {
        root.selectAll(".xfixed")
            .forEach(function (element, i) {
                element.transform(xfixed_t);
            });

        root.select(".ylabels")
            .transform(xfixed_t)
            .selectAll("text")
            .forEach(function (element, i) {
                if (element.attr("gadfly:inscale") == "true") {
                    var x = parseFloat(element.attr("y")) + ty;
                    element.attr("visibility",
                        bounds.y0 <= x && x <= bounds.y1 ? "visible" : "hidden");
                }
            });
    }

    if (xscalable) {
        root.selectAll(".yfixed")
            .forEach(function (element, i) {
                element.transform(yfixed_t);
            });

        root.select(".xlabels")
            .transform(yfixed_t)
            .selectAll("text")
            .forEach(function (element, i) {
                if (element.attr("gadfly:inscale") == "true") {
                    var x = parseFloat(element.attr("x")) + tx;
                    element.attr("visibility",
                        bounds.x0 <= x && x <= bounds.x1 ? "visible" : "hidden");
                }
            });
    }
};


var set_plot_zoom = function(root, scale) {
    // TODO: This is going to be painful, but here's the basic plan I have in
    // mind.
    //
    // The tick statistic is going to produce tick marks at various scales,
    // indexed by the scale at which they should be shown.
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

        root.data("tickscales", tickscales)
    }

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

    // TODO: This is going to be a problem. On firefox (dx, dy) is given
    // in client coordinates, whereas safari and chrome give these numbers
    // in pixels. Fuck my life.
    // 
    // Nope, that's not quite what's happening.
    // 
    // Ok, what's really happening is that firefox computes a bounding box
    // that includes all the invisible shit.
    //
    // At least, I think that's what's going on.
    // 
    dxdy = client_offset(fig, dx,  dy);
    dx = dxdy[0];
    dy = dxdy[1];

    // keep track of the last drag offset so we can fix tx on the drag
    // end event

    var tx0 = root.data("tx");
    var ty0 = root.data("ty");

    var pan_bounds = root.data("pan_bounds");
    tx1 = Math.max(pan_bounds.x0, Math.min(pan_bounds.x1, tx0 + dx));
    ty1 = Math.max(pan_bounds.y0, Math.min(pan_bounds.y1, ty0 + dy));

    root.data("dx", tx1 - tx0);
    root.data("dy", ty1 - ty0);

    set_plot_pan(root, tx1, ty1);
};


var guide_background_drag_onstart = function(x, y, event) {
    var root = this.plotroot();
    root.data("dx", 0);
    root.data("dy", 0);
    init_pan_zoom(root);
};


var guide_background_drag_onend = function(event) {
    var root = this.plotroot();
    root.data("tx", root.data("tx") + root.data("dx"));
    root.data("ty", root.data("ty") + root.data("dy"));
};


//@ sourceURL=gadfly.js
