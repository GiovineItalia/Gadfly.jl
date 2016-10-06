using Base.Test
using Gadfly, DataArrays, RDatasets, Distributions

global density_dark_tested

p = Gadfly.with_theme(:dark) do
    plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
end

# prevent these tests from running more than once
if !isdefined(:density_dark_tested)
    svg_str_dark = stringmime(MIME("image/svg+xml"), p)
    @test contains(svg_str_dark, hex(Gadfly.dark_theme.default_color))
    @test contains(svg_str_dark, hex(Gadfly.dark_theme.background_color))
    @test contains(svg_str_dark, hex(Gadfly.dark_theme.panel_fill))

    # Test reset.
    p2 = plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
    svg_str_light = stringmime(MIME("image/svg+xml"), p2)
    @test !contains(svg_str_light, hex(Gadfly.dark_theme.default_color))
    @test !contains(svg_str_light, hex(Gadfly.dark_theme.background_color))
    @test !contains(svg_str_light, hex(Gadfly.dark_theme.panel_fill))

    density_dark_tested=true
end

p
