using Gadfly, RDatasets, Test, Base64

set_default_plot_size(6inch, 3inch)


p = Gadfly.with_theme(:dark) do
    plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
end

    svg_str_dark = stringmime(MIME("image/svg+xml"), p)
    @test occursin(Base.hex(Gadfly.dark_theme.default_color), svg_str_dark)
#    @test occursin("rgba(34,40,48,1)", svg_str_dark) # dark theme background color
#    @test occursin("rgba(34,40,48,1)", svg_str_dark) # dark theme panel fill

    # Test reset.
    p2 = plot(dataset("ggplot2", "diamonds"), x="Price", color="Cut", Geom.density)
    svg_str_light = stringmime(MIME("image/svg+xml"), p2)
    @test !occursin(Base.hex(Gadfly.dark_theme.default_color), svg_str_light)
#    @test !occursin("rgba(34,40,48,1)", svg_str_light)


p
