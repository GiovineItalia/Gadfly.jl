

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
        element = this;
        while (!element.hasClass("plotroot") && element.parent() != null) {
            element = element.parent();
        }
        return element;
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

    root.selectAll(".geometry")
        .forEach(function (element, i) {
            element.transform("translate(" + tx + "," + ty + ")");
        });

    // TODO: translate, hide, and reveal tick marks.
    // TODO: translate, hide, and reveal grid lines
};


var set_plot_zoom = function(root, scale) {
    // TODO: This is going to be painful, but here's the basic plan I have in
    // mind.
    //
    // The tick statistic is going to produce tick marks at various scales,
    // indexed by the scale at which they should be shown.

};


// Panning
var guide_background_drag_onmove = function(dx, dy, x, y, event) {
    var root = this.plotroot();

    dxdy = client_offset(fig, dx,  dy);
    dx = dxdy[0];
    dy = dxdy[1];

    // keep track of the last drag offset so we can fix tx on the drag
    // end event
    root.data("dx", dx);
    root.data("dy", dy);

    var tx = root.data("tx");
    var ty = root.data("ty");
    set_plot_pan(root, tx + dx, ty + dy, 1.0);
};


var guide_background_drag_onstart = function(x, y, event) {
    var root = this.plotroot();
    root.data("dx", 0);
    root.data("dy", 0);
    if (root.data("tx") === undefined) root.data("tx", 0);
    if (root.data("ty") === undefined) root.data("ty", 0);
};


var guide_background_drag_onend = function(event) {
    var root = this.plotroot();
    root.data("tx", root.data("tx") + root.data("dx"));
    root.data("ty", root.data("ty") + root.data("dy"));
};


//@ sourceURL=gadfly.js
