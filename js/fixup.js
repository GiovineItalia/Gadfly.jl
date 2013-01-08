
// Ugly hacks to fix up the document after it's loaded. The alternative is
// hacking pandoc or feeding its output through a post processing script.
// This dynamic approach is the simplest way though.

function fixup() {
    // Do a little rearranging, nominating the first h1 tag found as the title.
    document.getElementById('title-block').appendChild(
        document.getElementsByTagName('h1')[0]);
    scroll(0, 0);

    // TODO: Screw with the table of contents that pandoc generates.
}

