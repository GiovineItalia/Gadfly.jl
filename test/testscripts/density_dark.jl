using Gadfly, RDatasets, Test, Base64

set_default_plot_size(6inch, 3inch)

global density_dark_tested

p = Gadfly.with_theme(:dark) do
    plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
end

# prevent these tests from running more than once
if ! @isdefined density_dark_tested
    svg_str_dark = stringmime(MIME("image/svg+xml"), p)
    @test occursin(hex(Gadfly.dark_theme.default_color), svg_str_dark)
    @test occursin(hex(Gadfly.dark_theme.background_color), svg_str_dark)
    @test occursin(hex(Gadfly.dark_theme.panel_fill), svg_str_dark)

    # Test reset.
    p2 = plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
    svg_str_light = stringmime(MIME("image/svg+xml"), p2)
    @test !occursin(hex(Gadfly.dark_theme.default_color), svg_str_light)
    @test !occursin(hex(Gadfly.dark_theme.background_color), svg_str_light)
    @test !occursin(hex(Gadfly.dark_theme.panel_fill), svg_str_light)

    density_dark_tested=true
end

p
