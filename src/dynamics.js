
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
function show_annotation(geom_id)
{
    annot_id = geom_id + "-annotation";
    annot = document.getElementById(annot_id);
    annot.setAttribute('visibility', 'visible');
    present_geometry([geom_id]);
}


// Turn off a possibly hidden annotation.
function hide_annotation(geom_id)
{
    annot_id = geom_id + "-annotation"
    annot = document.getElementById(annot_id)
    annot.setAttribute('visibility', 'hidden')
    unpresent_geometry();
}


// Dim all geometry objects with some exceptions.
function present_geometry(ids)
{
    on_anim_dur = 0.1;

    off_anim = document.getElementById('panel-focus-filter-off-anim');
    try {
        t0 = Number(off_anim.getStartTime());
    }
    catch (err) {
        t0 = Infinity;
    }
    off_anim.endElement();

    if (t0 < Infinity) {
        t = Number(off_anim.getCurrentTime());
        d = Number(off_anim.getSimpleDuration());
        from = Number(off_anim.getAttribute('from'));
        to = Number(off_anim.getAttribute('to'));
        p = Math.max(0.0, Math.min(1.0, ((t - t0) / d)));
        v = from + p * (to - from);
    }
    else {
        p=1.0;
        v=0.0;
    }

    geoms = document.getElementsByClassName('geometry');
    for (i = 0; i < geoms.length; ++i) {
        geoms[i].setAttribute('filter', 'url(#panel-focus-filter)');
    }

    for (i = 0; i < ids.length; ++i) {
        geom = document.getElementById(ids[i]);
        geom.setAttribute('filter', 'inherit');
    }

    on_anim = document.getElementById('panel-focus-filter-on-anim');
    on_anim.setAttribute('from', v);
    on_anim.setAttribute('dur',  p * on_anim_dur + 's');
    on_anim.beginElement();
}


// Set all geometries to full opacity.
function unpresent_geometry()
{
    off_anim_dur = 0.3;

    on_anim = document.getElementById('panel-focus-filter-on-anim');
    try {
        t0 = Number(on_anim.getStartTime());
        t = Number(on_anim.getCurrentTime());
        d = Number(on_anim.getSimpleDuration());
        p = Math.max(0.0, Math.min(1.0, ((t - t0) / d)));
    }
    catch (err) {
        p = 1.0;
    }
    on_anim.endElement();

    from = Number(on_anim.getAttribute('from'));
    to = Number(on_anim.getAttribute('to'));
    v = from + p * (to - from);

    off_anim = document.getElementById('panel-focus-filter-off-anim');
    off_anim.setAttribute('from', v);
    dur = p * off_anim_dur
    off_anim.setAttribute('dur',  dur + 's');
    off_anim.addEventListener('endEvent', unpresent_geometry_end);
    off_anim.beginElement();

    // Webkit doesn't support the "onend" attribute, so we work arround.
    setTimeout("unpresent_geometry_end()", 1000 * dur);
}


// Called when the animation in unpresent_geometry finishes.
// Enabling a filter, even if it has no effect, adds an extra layer of
// rasterization, which tends to make things look like shit, so we clear all the
// filters when the animation ends.
function unpresent_geometry_end()
{
    // skip this function in the on_animation has been triggered since the last
    // off_animation.
    on_anim = document.getElementById('panel-focus-filter-on-anim');
    off_anim = document.getElementById('panel-focus-filter-off-anim');
    if (on_anim.getStartTime() > off_anim.getStartTime()) {
        return;
    }

    // Skip this if the off animation isn't actually finished.
    elapsed = off_anim.getCurrentTime() - off_anim.getStartTime()
    if (elapsed < off_anim.getSimpleDuration()) {
        return;
    }

    geoms = document.getElementsByClassName('geometry');
    for (i = 0; i < geoms.length; ++i) {
        geoms[i].setAttribute('filter', 'inherit');
    }
}

