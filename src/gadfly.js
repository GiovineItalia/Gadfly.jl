

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


// Panning
var guide_background_drag_onmove = function(dx, dy, x, y, event) {
    // TODO
};


var guide_background_drag_onstart = function(x, y, event) {
    // TODO
};


var guide_background_drag_onend = function(event) {
     // TODO
};


//@ sourceURL=gadfly.js
