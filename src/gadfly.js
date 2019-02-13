
(function (glob, factory) {
    // AMD support
    if (typeof define === "function" && define.amd) {
        // Define as an anonymous module
        define("Gadfly", ["Snap.svg"], function (Snap) {
            return factory(Snap);
        });
    } else {
        // Browser globals (glob is window)
        // Snap adds itself to window
        glob.Gadfly = factory(glob.Snap);
    }
}(this, function (Snap) {

var Gadfly = {};

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

    Element.prototype.svgroot = function () {
        var element = this;
        while (element.node.nodeName != "svg" && element.parent() != null) {
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


    Element.prototype.mousewheel = function (fn, scope) {
        if (Snap.is(fn, "function")) {
            var el = this;
            var fn2 = function (event) {
                fn.apply(el, [event]);
            };
        }

        this.node.addEventListener(
            /Firefox/i.test(navigator.userAgent) ? "DOMMouseScroll" : "mousewheel",
            fn2);

        return this;
    };


    // Snap's attr function can be too slow for things like panning/zooming.
    // This is a function to directly update element attributes without going
    // through eve.
    Element.prototype.attribute = function(key, val) {
        if (val === undefined) {
            return this.node.getAttribute(key);
        } else {
            this.node.setAttribute(key, val);
            return this;
        }
    };

    Element.prototype.init_gadfly = function() {
        this.mouseenter(Gadfly.plot_mouseover)
            .mousemove(Gadfly.plot_mousemove)
            .mouseleave(Gadfly.plot_mouseout)
            .dblclick(Gadfly.plot_dblclick)
            .mousewheel(Gadfly.guide_background_scroll)
            .drag(Gadfly.guide_background_drag_onmove,
                  Gadfly.guide_background_drag_onstart,
                  Gadfly.guide_background_drag_onend);
        this.mouseenter(function (event) {
            init_pan_zoom(this.plotroot());
        });
        return this;
    };
});


Gadfly.plot_mousemove = function(event, x_px, y_px) {
    var root = this.plotroot();
    if (root.data("crosshair")) {
        px_per_mm = root.data("px_per_mm");
        bB = root.select('boundingbox').node.getAttribute('value').split(' ');
        uB = root.select('unitbox').node.getAttribute('value').split(' ');
        xscale = root.data("xscale");
        yscale = root.data("yscale");
        xtranslate = root.data("tx");
        ytranslate = root.data("ty");

        xoff_mm = bB[0].substr(0,bB[0].length-2)/1;
        yoff_mm = bB[1].substr(0,bB[1].length-2)/1;
        xoff_unit = uB[0]/1;
        yoff_unit = uB[1]/1;
        mm_per_xunit = bB[2].substr(0,bB[2].length-2) / uB[2];
        mm_per_yunit = bB[3].substr(0,bB[3].length-2) / uB[3];
         
        x_unit = ((x_px / px_per_mm - xtranslate) / xscale - xoff_mm) / mm_per_xunit + xoff_unit;
        y_unit = ((y_px / px_per_mm - ytranslate) / yscale - yoff_mm) / mm_per_yunit + yoff_unit;

        root.select('.crosshair').select('.primitive').select('text')
                .node.innerHTML = x_unit.toPrecision(3)+","+y_unit.toPrecision(3);
    };
};

Gadfly.helpscreen_visible = function(event) {
    helpscreen_visible(this.plotroot());
};
var helpscreen_visible = function(root) {
    root.select(".helpscreen").animate({"fill-opacity": 1.0}, 250);
};

Gadfly.helpscreen_hidden = function(event) {
    helpscreen_hidden(this.plotroot());
};
var helpscreen_hidden = function(root) {
    root.select(".helpscreen").animate({"fill-opacity": 0.0}, 250);
};

// When the plot is moused over, emphasize the grid lines.
Gadfly.plot_mouseover = function(event) {
    var root = this.plotroot();

    var keyboard_help = function(event) {
        if (event.which == 191) { // ?
            helpscreen_visible(root);
        }
    };
    root.data("keyboard_help", keyboard_help);
    window.addEventListener("keydown", keyboard_help);

    var keyboard_pan_zoom = function(event) {
        var bounds = root.plotbounds(),
            width = bounds.x1 - bounds.x0;
            height = bounds.y1 - bounds.y0;
        if (event.which == 187 || event.which == 73) { // plus or i
            increase_zoom_by_position(root, 0.1, true);
        } else if (event.which == 189 || event.which == 79) { // minus or o
            increase_zoom_by_position(root, -0.1, true);
        } else if (event.which == 39 || event.which == 76) { // right-arrow or l
            set_plot_pan_zoom(root, root.data("tx")-width/10, root.data("ty"),
                    root.data("xscale"), root.data("yscale"));
        } else if (event.which == 40 || event.which == 74) { // down-arrow or j
            set_plot_pan_zoom(root, root.data("tx"), root.data("ty")-height/10,
                    root.data("xscale"), root.data("yscale"));
        } else if (event.which == 37 || event.which == 72) { // left-arrow or h
            set_plot_pan_zoom(root, root.data("tx")+width/10, root.data("ty"),
                    root.data("xscale"), root.data("yscale"));
        } else if (event.which == 38 || event.which == 75) { // up-arrow or k
            set_plot_pan_zoom(root, root.data("tx"), root.data("ty")+height/10,
                    root.data("xscale"), root.data("yscale"));
        } else if (event.which == 82) { // r
            set_plot_pan_zoom(root, 0.0, 0.0, 1.0, 1.0);
        } else if (event.which == 191) { // ?
            helpscreen_hidden(root);
        } else if (event.which == 67) { // c
            root.data("crosshair",!root.data("crosshair"));
            root.select(".crosshair")
                .animate({"fill-opacity": root.data("crosshair") ? 1.0 : 0.0}, 250);
        }
    };
    root.data("keyboard_pan_zoom", keyboard_pan_zoom);
    window.addEventListener("keyup", keyboard_pan_zoom);

    var xgridlines = root.select(".xgridlines"),
        ygridlines = root.select(".ygridlines");

    if (xgridlines) {
        xgridlines.data("unfocused_strokedash",
                        xgridlines.attribute("stroke-dasharray").replace(/(\d)(,|$)/g, "$1mm$2"));
        var destcolor = root.data("focused_xgrid_color");
        xgridlines.attribute("stroke-dasharray", "none")
                  .selectAll("path")
                  .animate({stroke: destcolor}, 250);
    }

    if (ygridlines) {
        ygridlines.data("unfocused_strokedash",
                        ygridlines.attribute("stroke-dasharray").replace(/(\d)(,|$)/g, "$1mm$2"));
        var destcolor = root.data("focused_ygrid_color");
        ygridlines.attribute("stroke-dasharray", "none")
                  .selectAll("path")
                  .animate({stroke: destcolor}, 250);
    }

    root.select(".crosshair")
        .animate({"fill-opacity": root.data("crosshair") ? 1.0 : 0.0}, 250);
    root.select(".questionmark").animate({"fill-opacity": 1.0}, 250);
};

// Reset pan and zoom on double click
Gadfly.plot_dblclick = function(event) {
  set_plot_pan_zoom(this.plotroot(), 0.0, 0.0, 1.0, 1.0);
};

// Unemphasize grid lines on mouse out.
Gadfly.plot_mouseout = function(event) {
    var root = this.plotroot();

    window.removeEventListener("keyup", root.data("keyboard_pan_zoom"));
    root.data("keyboard_pan_zoom", undefined);
    window.removeEventListener("keydown", root.data("keyboard_help"));
    root.data("keyboard_help", undefined);

    var xgridlines = root.select(".xgridlines"),
        ygridlines = root.select(".ygridlines");

    if (xgridlines) {
        var destcolor = root.data("unfocused_xgrid_color");
        xgridlines.attribute("stroke-dasharray", xgridlines.data("unfocused_strokedash"))
                  .selectAll("path")
                  .animate({stroke: destcolor}, 250);
    }

    if (ygridlines) {
        var destcolor = root.data("unfocused_ygrid_color");
        ygridlines.attribute("stroke-dasharray", ygridlines.data("unfocused_strokedash"))
                  .selectAll("path")
                  .animate({stroke: destcolor}, 250);
    }

    root.select(".crosshair").animate({"fill-opacity": 0.0}, 250);
    root.select(".questionmark").animate({"fill-opacity": 0.0}, 250);
    helpscreen_hidden(root);
};


var set_geometry_transform = function(root, tx, ty, xscale, yscale) {
    var xscalable = root.hasClass("xscalable"),
        yscalable = root.hasClass("yscalable");

    var old_xscale = root.data("xscale"),
        old_yscale = root.data("yscale");

    var xscale = xscalable ? xscale : 1.0,
        yscale = yscalable ? yscale : 1.0;

    tx = xscalable ? tx : 0.0;
    ty = yscalable ? ty : 0.0;

    var t = new Snap.Matrix().translate(tx, ty).scale(xscale, yscale);
    root.selectAll(".geometry, image").forEach(function (element, i) {
            element.transform(t);
        });

    var t = new Snap.Matrix().scale(1.0/xscale, 1.0/yscale);
    root.selectAll('.marker').forEach(function (element, i) {
        element.selectAll('.primitive').forEach(function (element, i) {
            element.transform(t);
        }) });

    bounds = root.plotbounds();
    px_per_mm = root.data("px_per_mm");

    if (yscalable) {
        var xfixed_t = new Snap.Matrix().translate(0, ty).scale(1.0, yscale);
        root.selectAll(".xfixed")
            .forEach(function (element, i) {
                element.transform(xfixed_t);
            });

        ylabels = root.select(".ylabels");
        if (ylabels) {
            ylabels.transform(xfixed_t)
                   .selectAll("g")
                   .forEach(function (element, i) {
                       if (element.attribute("gadfly:inscale") == "true") {
                           unscale_t = new Snap.Matrix();
                           unscale_t.scale(1, 1/yscale);
                           element.select("text").transform(unscale_t);
 
                           var y = element.attr("transform").globalMatrix.f / px_per_mm;
                           element.attr("visibility",
                               bounds.y0 <= y && y <= bounds.y1 ? "visible" : "hidden");
                       }
                   });
        }
    }

    if (xscalable) {
        var yfixed_t = new Snap.Matrix().translate(tx, 0).scale(xscale, 1.0);
        var xtrans = new Snap.Matrix().translate(tx, 0);
        root.selectAll(".yfixed")
            .forEach(function (element, i) {
                element.transform(yfixed_t);
            });

        xlabels = root.select(".xlabels");
        if (xlabels) {
            xlabels.transform(yfixed_t)
                   .selectAll("g")
                   .forEach(function (element, i) {
                       if (element.attribute("gadfly:inscale") == "true") {
                           unscale_t = new Snap.Matrix();
                           unscale_t.scale(1/xscale, 1);
                           element.select("text").transform(unscale_t);

                           var x = element.attr("transform").globalMatrix.e / px_per_mm;
                           element.attr("visibility",
                               bounds.x0 <= x && x <= bounds.x1 ? "visible" : "hidden");
                           }
                   });
        }
    }
};


// Find the most appropriate tick scale and update label visibility.
var update_tickscale = function(root, scale, axis) {
    if (!root.hasClass(axis + "scalable")) return;

    var tickscales = root.data(axis + "tickscales");
    var best_tickscale = 1.0;
    var best_tickscale_dist = Infinity;
    for (tickscale in tickscales) {
        var dist = Math.abs(Math.log(tickscale) - Math.log(scale));
        if (dist < best_tickscale_dist) {
            best_tickscale_dist = dist;
            best_tickscale = tickscale;
        }
    }

    if (best_tickscale != root.data(axis + "tickscale")) {
        root.data(axis + "tickscale", best_tickscale);
        var mark_inscale_gridlines = function (element, i) {
            if (element.attribute("gadfly:inscale") == null) { return; }
            var inscale = element.attr("gadfly:scale") == best_tickscale;
            element.attribute("gadfly:inscale", inscale);
            element.attr("visibility", inscale ? "visible" : "hidden");
        };

        var mark_inscale_labels = function (element, i) {
            if (element.attribute("gadfly:inscale") == null) { return; }
            var inscale = element.attr("gadfly:scale") == best_tickscale;
            element.attribute("gadfly:inscale", inscale);
            element.attr("visibility", inscale ? "visible" : "hidden");
        };

        root.select("." + axis + "gridlines").selectAll("g").forEach(mark_inscale_gridlines);
        root.select("." + axis + "labels").selectAll("g").forEach(mark_inscale_labels);
    }
};


var set_plot_pan_zoom = function(root, tx, ty, xscale, yscale) {
    var old_xscale = root.data("xscale"),
        old_yscale = root.data("yscale");
    var bounds = root.plotbounds();

    var width = bounds.x1 - bounds.x0,
        height = bounds.y1 - bounds.y0;

    // compute the viewport derived from tx, ty, xscale, and yscale
    var x_min = -width * xscale - (xscale * width - width),
        x_max = width * xscale,
        y_min = -height * yscale - (yscale * height - height),
        y_max = height * yscale;

    var x0 = bounds.x0 - xscale * bounds.x0,
        y0 = bounds.y0 - yscale * bounds.y0;

    var tx = Math.max(Math.min(tx - x0, x_max), x_min),
        ty = Math.max(Math.min(ty - y0, y_max), y_min);

    tx += x0;
    ty += y0;

    // when the scale changes, we may need to alter which set of
    // ticks are being displayed
    if (xscale != old_xscale) {
        update_tickscale(root, xscale, "x");
    }
    if (yscale != old_yscale) {
        update_tickscale(root, yscale, "y");
    }

    set_geometry_transform(root, tx, ty, xscale, yscale);

    root.data("xscale", xscale);
    root.data("yscale", yscale);
    root.data("tx", tx);
    root.data("ty", ty);
};


var scale_centered_translation = function(root, xscale, yscale) {
    var bounds = root.plotbounds();

    var width = bounds.x1 - bounds.x0,
        height = bounds.y1 - bounds.y0;

    var tx0 = root.data("tx"),
        ty0 = root.data("ty");

    var xscale0 = root.data("xscale"),
        yscale0 = root.data("yscale");

    // how off from center the current view is
    var xoff = tx0 - (bounds.x0 * (1 - xscale0) + (width * (1 - xscale0)) / 2),
        yoff = ty0 - (bounds.y0 * (1 - yscale0) + (height * (1 - yscale0)) / 2);

    // rescale offsets
    xoff = xoff * xscale / xscale0;
    yoff = yoff * yscale / yscale0;

    // adjust for the panel position being scaled
    var x_edge_adjust = bounds.x0 * (1 - xscale),
        y_edge_adjust = bounds.y0 * (1 - yscale);

    return {
        x: xoff + x_edge_adjust + (width - width * xscale) / 2,
        y: yoff + y_edge_adjust + (height - height * yscale) / 2
    };
};


// Initialize data for panning zooming if it isn't already.
var init_pan_zoom = function(root) {
    if (root.data("zoompan-ready")) {
        return;
    }

    root.data("crosshair",false);

    // The non-scaling-stroke trick. Rather than try to correct for the
    // stroke-width when zooming, we force it to a fixed value.
    var px_per_mm = root.node.getCTM().a;

    // Drag events report deltas in pixels, which we'd like to convert to
    // millimeters.
    root.data("px_per_mm", px_per_mm);

    root.selectAll("path")
        .forEach(function (element, i) {
        sw = element.asPX("stroke-width") * px_per_mm;
        if (sw > 0) {
            element.attribute("stroke-width", sw);
            element.attribute("vector-effect", "non-scaling-stroke");
        }
    });

    // Store ticks labels original tranformation
    root.selectAll(".xlabels > g, .ylabels > g")
        .forEach(function (element, i) {
            var lm = element.transform().localMatrix;
            element.data("static_transform",
                new Snap.Matrix(lm.a, lm.b, lm.c, lm.d, lm.e, lm.f));
        });

    var xgridlines = root.select(".xgridlines");
    var ygridlines = root.select(".ygridlines");
    var xlabels = root.select(".xlabels");
    var ylabels = root.select(".ylabels");

    if (root.data("tx") === undefined) root.data("tx", 0);
    if (root.data("ty") === undefined) root.data("ty", 0);
    if (root.data("xscale") === undefined) root.data("xscale", 1.0);
    if (root.data("yscale") === undefined) root.data("yscale", 1.0);
    if (root.data("xtickscales") === undefined) {

        // index all the tick scales that are listed
        var xtickscales = {};
        var ytickscales = {};
        var add_x_tick_scales = function (element, i) {
            if (element.attribute("gadfly:scale")==null) { return; }
            xtickscales[element.attribute("gadfly:scale")] = true;
        };
        var add_y_tick_scales = function (element, i) {
            if (element.attribute("gadfly:scale")==null) { return; }
            ytickscales[element.attribute("gadfly:scale")] = true;
        };

        if (xgridlines) xgridlines.selectAll("g").forEach(add_x_tick_scales);
        if (ygridlines) ygridlines.selectAll("g").forEach(add_y_tick_scales);
        if (xlabels) xlabels.selectAll("g").forEach(add_x_tick_scales);
        if (ylabels) ylabels.selectAll("g").forEach(add_y_tick_scales);

        root.data("xtickscales", xtickscales);
        root.data("ytickscales", ytickscales);
        root.data("xtickscale", 1.0);
        root.data("ytickscale", 1.0);  // ???
    }

    var min_scale = 1.0, max_scale = 1.0;
    for (scale in xtickscales) {
        min_scale = Math.min(min_scale, scale);
        max_scale = Math.max(max_scale, scale);
    }
    for (scale in ytickscales) {
        min_scale = Math.min(min_scale, scale);
        max_scale = Math.max(max_scale, scale);
    }
    root.data("min_scale", min_scale);
    root.data("max_scale", max_scale);

    // store the original positions of labels
    if (xlabels) {
        xlabels.selectAll("g")
               .forEach(function (element, i) {
                   element.data("x", element.asPX("x"));
               });
    }

    if (ylabels) {
        ylabels.selectAll("g")
               .forEach(function (element, i) {
                   element.data("y", element.asPX("y"));
               });
    }

    // mark grid lines and ticks as in or out of scale.
    var mark_inscale = function (element, i) {
        if (element.attribute("gadfly:scale") == null) { return; }
        element.attribute("gadfly:inscale", element.attribute("gadfly:scale") == 1.0);
    };

    if (xgridlines) xgridlines.selectAll("g").forEach(mark_inscale);
    if (ygridlines) ygridlines.selectAll("g").forEach(mark_inscale);
    if (xlabels) xlabels.selectAll("g").forEach(mark_inscale);
    if (ylabels) ylabels.selectAll("g").forEach(mark_inscale);

    // figure out the upper ond lower bounds on panning using the maximum
    // and minum grid lines
    var bounds = root.plotbounds();
    var pan_bounds = {
        x0: 0.0,
        y0: 0.0,
        x1: 0.0,
        y1: 0.0
    };

    if (xgridlines) {
        xgridlines
            .selectAll("g")
            .forEach(function (element, i) {
                if (element.attribute("gadfly:inscale") == "true") {
                    var bbox = element.node.getBBox();
                    if (bounds.x1 - bbox.x < pan_bounds.x0) {
                        pan_bounds.x0 = bounds.x1 - bbox.x;
                    }
                    if (bounds.x0 - bbox.x > pan_bounds.x1) {
                        pan_bounds.x1 = bounds.x0 - bbox.x;
                    }
                    element.attr("visibility", "visible");
                }
            });
    }

    if (ygridlines) {
        ygridlines
            .selectAll("g")
            .forEach(function (element, i) {
                if (element.attribute("gadfly:inscale") == "true") {
                    var bbox = element.node.getBBox();
                    if (bounds.y1 - bbox.y < pan_bounds.y0) {
                        pan_bounds.y0 = bounds.y1 - bbox.y;
                    }
                    if (bounds.y0 - bbox.y > pan_bounds.y1) {
                        pan_bounds.y1 = bounds.y0 - bbox.y;
                    }
                    element.attr("visibility", "visible");
                }
            });
    }

    // nudge these values a little
    pan_bounds.x0 -= 5;
    pan_bounds.x1 += 5;
    pan_bounds.y0 -= 5;
    pan_bounds.y1 += 5;
    root.data("pan_bounds", pan_bounds);

    root.data("zoompan-ready", true)
};


// drag actions, i.e. zooming and panning
var pan_action = {
    start: function(root, x, y, event) {
        root.data("dx", 0);
        root.data("dy", 0);
        root.data("tx0", root.data("tx"));
        root.data("ty0", root.data("ty"));
    },
    update: function(root, dx, dy, x, y, event) {
        var px_per_mm = root.data("px_per_mm");
        dx /= px_per_mm;
        dy /= px_per_mm;

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

        set_plot_pan_zoom(root, tx, ty, root.data("xscale"), root.data("yscale"));
    },
    end: function(root, event) {

    },
    cancel: function(root) {
        set_plot_pan_zoom(root, root.data("tx0"), root.data("ty0"),
                root.data("xscale"), root.data("yscale"));
    }
};

var zoom_box;
var zoom_action = {
    start: function(root, x, y, event) {
        var bounds = root.plotbounds();
        var width = bounds.x1 - bounds.x0,
            height = bounds.y1 - bounds.y0;
        var xscalable = root.hasClass("xscalable"),
            yscalable = root.hasClass("yscalable");
        var px_per_mm = root.data("px_per_mm");
        x = xscalable ? x / px_per_mm : bounds.x0;
        y = yscalable ? y / px_per_mm : bounds.y0;
        var w = xscalable ? 0 : width;
        var h = yscalable ? 0 : height;
        zoom_box = root.rect(x, y, w, h).attr({
            "fill": "#000",
            "fill-opacity": 0.25
        });
    },
    update: function(root, dx, dy, x, y, event) {
        var xscalable = root.hasClass("xscalable"),
            yscalable = root.hasClass("yscalable");
        var px_per_mm = root.data("px_per_mm");
        var bounds = root.plotbounds();
        if (yscalable) {
            y /= px_per_mm;
            y = Math.max(bounds.y0, y);
            y = Math.min(bounds.y1, y);
        } else {
            y = bounds.y1;
        }
        if (xscalable) {
            x /= px_per_mm;
            x = Math.max(bounds.x0, x);
            x = Math.min(bounds.x1, x);
        } else {
            x = bounds.x1;
        }

        dx = x - zoom_box.attr("x");
        dy = y - zoom_box.attr("y");
        var xoffset = 0,
            yoffset = 0;
        if (dx < 0) {
            xoffset = dx;
            dx = -1 * dx;
        }
        if (dy < 0) {
            yoffset = dy;
            dy = -1 * dy;
        }
        if (isNaN(dy)) {
            dy = 0.0;
        }
        if (isNaN(dx)) {
            dx = 0.0;
        }
        zoom_box.transform("T" + xoffset + "," + yoffset);
        zoom_box.attr("width", dx);
        zoom_box.attr("height", dy);
    },
    end: function(root, event) {
        var xscalable = root.hasClass("xscalable"),
            yscalable = root.hasClass("yscalable");
        var zoom_bounds = zoom_box.getBBox();
        if (zoom_bounds.width * zoom_bounds.height <= 0) {
            return;
        }
        var plot_bounds = root.plotbounds();
        var xzoom_factor = 1.0,
            yzoom_factor = 1.0;
        if (xscalable) {
            xzoom_factor = (plot_bounds.x1 - plot_bounds.x0) / zoom_bounds.width;
        }
        if (yscalable) {
            yzoom_factor = (plot_bounds.y1 - plot_bounds.y0) / zoom_bounds.height;
        }
        var tx = (root.data("tx") - zoom_bounds.x) * xzoom_factor + plot_bounds.x0,
            ty = (root.data("ty") - zoom_bounds.y) * yzoom_factor + plot_bounds.y0;
        set_plot_pan_zoom(root, tx, ty,
                root.data("xscale") * xzoom_factor, root.data("yscale") * yzoom_factor);
        zoom_box.remove();
    },
    cancel: function(root) {
        zoom_box.remove();
    }
};


Gadfly.guide_background_drag_onstart = function(x, y, event) {
    var root = this.plotroot();
    var scalable = root.hasClass("xscalable") || root.hasClass("yscalable");
    var zoomable = !event.altKey && !event.ctrlKey && event.shiftKey && scalable;
    var panable = !event.altKey && !event.ctrlKey && !event.shiftKey && scalable;
    var drag_action = zoomable ? zoom_action :
                      panable  ? pan_action :
                                 undefined;
    root.data("drag_action", drag_action);
    if (drag_action) {
        var cancel_drag_action = function(event) {
            if (event.which == 27) { // esc key
                drag_action.cancel(root);
                root.data("drag_action", undefined);
            }
        };
        window.addEventListener("keyup", cancel_drag_action);
        root.data("cancel_drag_action", cancel_drag_action);
        drag_action.start(root, x, y, event);
    }
};


Gadfly.guide_background_drag_onmove = function(dx, dy, x, y, event) {
    var root = this.plotroot();
    var drag_action = root.data("drag_action");
    if (drag_action) {
        drag_action.update(root, dx, dy, x, y, event);
    }
};


Gadfly.guide_background_drag_onend = function(event) {
    var root = this.plotroot();
    window.removeEventListener("keyup", root.data("cancel_drag_action"));
    root.data("cancel_drag_action", undefined);
    var drag_action = root.data("drag_action");
    if (drag_action) {
        drag_action.end(root, event);
    }
    root.data("drag_action", undefined);
};


Gadfly.guide_background_scroll = function(event) {
    if (event.shiftKey) {
        increase_zoom_by_position(this.plotroot(), 0.001 * event.wheelDelta);
        event.preventDefault();
    }
};

// Map slider position x to scale y using the function y = a*exp(b*x)+c.
// The constants a, b, and c are solved using the constraint that the function
// should go through the points (0; min_scale), (0.5; 1), and (1; max_scale).
var scale_from_slider_position = function(position, min_scale, max_scale) {
    if (min_scale==max_scale) { return 1; }
    var a = (1 - 2 * min_scale + min_scale * min_scale) / (min_scale + max_scale - 2),
        b = 2 * Math.log((max_scale - 1) / (1 - min_scale)),
        c = (min_scale * max_scale - 1) / (min_scale + max_scale - 2);
    return a * Math.exp(b * position) + c;
}

// inverse of scale_from_slider_position
var slider_position_from_scale = function(scale, min_scale, max_scale) {
    if (min_scale==max_scale) { return min_scale; }
    var a = (1 - 2 * min_scale + min_scale * min_scale) / (min_scale + max_scale - 2),
        b = 2 * Math.log((max_scale - 1) / (1 - min_scale)),
        c = (min_scale * max_scale - 1) / (min_scale + max_scale - 2);
    return 1 / b * Math.log((scale - c) / a);
}

var increase_zoom_by_position = function(root, delta_position, animate) {
    var old_xscale = root.data("xscale"),
        old_yscale = root.data("yscale"),
        min_scale = root.data("min_scale"),
        max_scale = root.data("max_scale");
    var xposition = slider_position_from_scale(old_xscale, min_scale, max_scale),
        yposition = slider_position_from_scale(old_yscale, min_scale, max_scale);
    xposition += (root.hasClass("xscalable") ? delta_position : 0.0);
    yposition += (root.hasClass("yscalable") ? delta_position : 0.0);
    old_xscale = scale_from_slider_position(xposition, min_scale, max_scale);
    old_yscale = scale_from_slider_position(yposition, min_scale, max_scale);
    var new_xscale = Math.max(min_scale, Math.min(old_xscale, max_scale)),
        new_yscale = Math.max(min_scale, Math.min(old_yscale, max_scale));
    if (animate) {
        Snap.animate(
            [old_xscale, old_yscale],
            [new_xscale, new_yscale],
            function (new_scale) {
                update_plot_scale(root, new_scale[0], new_scale[1]);
            },
            200);
    } else {
        update_plot_scale(root, new_xscale, new_yscale);
    }
}


var update_plot_scale = function(root, new_xscale, new_yscale) {
    var trans = scale_centered_translation(root, new_xscale, new_yscale);
    set_plot_pan_zoom(root, trans.x, trans.y, new_xscale, new_yscale);
};


var toggle_color_class = function(root, color_class, ison) {
    var escaped_color_class = color_class.replace(/([^0-9a-zA-z])/g,"\\$1");
    var guides = root.selectAll(".guide." + escaped_color_class + ",.guide ." + escaped_color_class);
    var geoms = root.selectAll(".geometry." + escaped_color_class + ",.geometry ." + escaped_color_class);
    if (ison) {
        guides.animate({opacity: 0.5}, 250);
        geoms.animate({opacity: 0.0}, 250);
    } else {
        guides.animate({opacity: 1.0}, 250);
        geoms.animate({opacity: 1.0}, 250);
    }
};


Gadfly.colorkey_swatch_click = function(event) {
    var root = this.plotroot();
    var color_class = this.data("color_class");

    if (event.shiftKey) {
        root.selectAll(".colorkey g")
            .forEach(function (element) {
                var other_color_class = element.data("color_class");
                if (typeof other_color_class !== 'undefined' && other_color_class != color_class) {
                    toggle_color_class(root, other_color_class,
                                       element.attr("opacity") == 1.0);
                }
            });
    } else {
        toggle_color_class(root, color_class, this.attr("opacity") == 1.0);
    }
};


return Gadfly;

}));


//@ sourceURL=gadfly.js
