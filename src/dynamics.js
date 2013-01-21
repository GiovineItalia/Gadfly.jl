
// Functions embedded in Gadfly plots to add interactivity.


// Clicking an entry in a color key toggles visibility of the data within that
// group.
function toggle_color_group(name)
{
    geoms = document.getElementsByClassName('color_group_' + name);
    entry = document.getElementById('color_key_' + name);
    state = geoms[0].getAttribute('visibility');
    if (!state || state == 'visible') {
        for (i = 0; i < geoms.length; ++i) {
            geoms[i].setAttribute('visibility', 'hidden');
        }
        entry.setAttribute('opacity', 0.5);
    } else {
        for (i = 0; i < geoms.length; ++i) {
            geoms[i].setAttribute('visibility', 'visible');
        }
        entry.setAttribute('opacity', 1.0);
    }
}


// Turn on a possibily hidden annotation.
function show_annotation(id)
{
    annot = document.getElementById(id)
    annot.setAttribute('visibility', 'visible')
}


// Turn off a possibly hidden annotation.
function hide_annotation(id)
{
    annot = document.getElementById(id)
    annot.setAttribute('visibility', 'hidden')
}


// Dim all geometry objects with some exceptions.
function present_geometry(ids)
{
    geoms = document.getElementsByClassName('geometry');
    for (i = 0; i < geoms.length; ++i) {
        geoms[i].setAttribute('opacity', 0.2);
    }

    for (i = 0; i < ids.length; ++i) {
        console.info(ids[i]);
        geom = document.getElementById(ids[i]);
        geom.setAttribute('opacity', 1.0);
    }
}


// Set all geometries to full opacity.
function unpresent_geometry()
{
    geoms = document.getElementsByClassName('geometry');
    for (i = 0; i < geoms.length; ++i) {
        geoms[i].setAttribute('opacity', 1.0);
    }
}

