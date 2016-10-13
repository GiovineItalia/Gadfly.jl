#!/usr/bin/env julia

global prev_theme=nothing

if haskey(ENV, "GADFLY_THEME")
    prev_theme = ENV["GADFLY_THEME"]
    pop!(ENV, "GADFLY_THEME")
end

using RDatasets, Gadfly, Compat

tests = [
    ("points",                                6inch, 3inch),
    ("noticks",                               6inch, 3inch),
    ("point_shape",                           6inch, 6inch),
    ("colored_points",                        6inch, 3inch),
    ("function_plots",                        6inch, 3inch),
    ("function_explicit_colors",              6inch, 3inch),
    ("function_layers",                       6inch, 3inch),
    ("multicolumn_colorkey",                  6inch, 2inch),
    ("vstack",                                6inch, 6inch),
    ("hstack",                                6inch, 3inch),
    ("colorful_hist",                         6inch, 3inch),
    ("discrete_histogram",                    6inch, 3inch),
    ("discrete_bar",                          6inch, 3inch),
    ("discrete_bar_horizontal",               6inch, 3inch),
    ("stacked_discrete_histogram",            6inch, 3inch),
    ("stacked_discrete_histogram_horizontal", 6inch, 3inch),
    ("stacked_continuous_histogram",          6inch, 3inch),
    ("dodged_discrete_histogram",             6inch, 3inch),
    ("dodged_discrete_histogram_horizontal",  6inch, 3inch),
    ("array_aesthetics",                      6inch, 3inch),
    ("subplot_grid",                          10inch, 10inch),
    ("subplot_grid_free_axis",                10inch, 10inch),
    ("subplot_grid_histogram",                10inch, 3inch),
    ("subplot_layers",                        8inch, 6inch),
    ("labels",                                6inch, 6inch),
    ("percent",                               6inch, 6inch),
    ("timeseries_day",                        6inch, 3inch),
    ("timeseries_month",                      6inch, 3inch),
    ("timeseries_year_1",                     6inch, 3inch),
    ("timeseries_year_2",                     6inch, 3inch),
    ("timeseries_year_3",                     6inch, 3inch),
    ("timeseries_colorful",                   6inch, 3inch),
    ("date_bar",                              6inch, 3inch),
    ("custom_themes",                         6inch, 3inch),
    ("issue98",                               6inch, 3inch),
    ("issue82",                               6inch, 3inch),
    ("histogram2d",                           6inch, 3inch),
    ("rectbin",                               6inch, 3inch),
    ("density",                               6inch, 3inch),
    ("density_dark",                          6inch, 3inch),
    ("colorful_density",                      6inch, 3inch),
    ("explicit_colorkey_title",               6inch, 3inch),
    ("explicit_subplot_titles",               6inch, 3inch),
    ("subplot_grid_smooth",                   6inch, 8inch),
    ("smooth_lm",                             6inch, 8inch),
    ("colored_smooth_lm",                     6inch, 8inch),
    ("histogram_errorbar",                    6inch, 3inch),
    ("issue106",                              6inch, 3inch),
    ("continuous_color_scale_range",          6inch, 3inch),
    ("continuous_scale_range",                6inch, 3inch),
    ("log10_scale_range",                     6inch, 3inch),
    ("histogram_explicit_bins",               6inch, 3inch),
    ("histogram2d_explicit_bins",             6inch, 3inch),
    ("explicit_number_format",                6inch, 3inch),
    ("explicit_xy_ticks",                     6inch, 3inch),
    ("boxplot",                               6inch, 3inch),
    ("subplot_categorical_bar",               6inch, 3inch),
    ("errorbar",                              6inch, 3inch),
    ("issue120",                              6inch, 3inch),
    ("histogram2d_discrete",                  6inch, 3inch),
    ("layer_themes",                          6inch, 3inch),
    ("layer_guide",                           6inch, 3inch),
    ("discrete_color_manual",                 6inch, 3inch),
    ("lab_gradient",                          6inch, 3inch),
    ("contour_color_none",                    6inch, 3inch),
    ("ordered_line",                          6inch, 3inch),
    ("nan_skipping",                          6inch, 3inch),
    ("hexbin",                                6inch, 3inch),
    ("hexbin_dark",                           6inch, 3inch),
    ("spy",                                   6inch, 3inch),
    ("issue177",                              6inch, 3inch),
    ("ribbon",                                6inch, 3inch),
    ("colored_ribbon",                        6inch, 3inch),
    ("layer_leak",                            6inch, 3inch),
    ("hline_vline",                           6inch, 3inch),
    ("grid_strokedash",                       6inch, 3inch),
    ("aspect_ratio",                          6inch, 3inch),
    ("contour_function",                      6inch, 3inch),
    ("contour_matrix",                        6inch, 3inch),
    ("contour_layers",                        6inch, 3inch),
    ("stat_qq",                               6inch, 16inch),
    ("line_histogram",                        6inch, 3inch),
    ("layer_data",                            6inch, 3inch),
    ("multi_geom_layer",                      6inch, 3inch),
    ("raster",                                6inch, 3inch),
    ("single_boxplot",                        6inch, 3inch),
    ("subplot_scales",                        6inch, 3inch),
    ("issue509",                              6inch, 3inch),
    ("layer_order",                           6inch, 3inch),
    ("single_datetime",                       6inch, 3inch),
    ("layered_subplots",                      6inch, 6inch),
    ("subplot_layer_data",                    6inch, 6inch),
    ("static_label_layout",                   6inch, 16inch),
    ("subplot_grid_free_y_1",                 30cm,  10cm),
    ("subplot_grid_free_y_2",                 10cm,  30cm),
    ("violin",                                6inch, 3inch),
    ("single_violin",                         6inch, 3inch),
    ("polygon",                               6inch, 3inch),
    ("jitter",                                6inch, 3inch),
    ("stat_binmean",                          6inch, 12inch),
    ("step",                                  6inch, 3inch),
    ("auto_enumerate",                        6inch, 3inch),
    ("coord_limits",                          6inch, 6inch),
    ("rug",                                   6inch, 3inch),
    ("beeswarm",                              6inch, 3inch),
    ("issue871",                              6inch, 3inch),
    ("issue882",                              6inch, 3inch),
    ("vector",                                3.3inch, 3.3inch)
]


backends = @compat Dict{AbstractString, Function}(
    "svg" => (name, width, height) -> SVG("output/$(name).svg", width, height),
    "svgjs" => (name, width, height) -> SVGJS("output/$(name).js.svg", width, height, jsmode=:linkabs),
    "png" => (name, width, height) -> PNG("output/$(name).png", width, height),
    #"ps"  => (name, width, height) -> PS("output/$(name).ps",   width, height),
    #"pdf" => (name, width, height) -> PDF("output/$(name).pdf", width, height)
    "pgf" => (name, width, height) -> PGF("output/$(name).tex", width, height)
)


function run_tests(output_filename)
    testdir = dirname(@__FILE__)
    whitelist = Set()
    if !isempty(ARGS)
        union!(whitelist, ARGS)
    else
        union!(whitelist, [name for (name, width, height) in tests])
    end

    for (name, width, height) in tests
        if !in(name, whitelist)
            continue
        end

        for (backend_name, backend) in backends
            println(STDERR, "Rendering $(name) on $(backend_name) backend.")
            try
                p = evalfile(joinpath(testdir, "$(name).jl"))
                @time draw(backend(name, width, height), p)
            catch
                println(STDERR, "FAILED!")
                rethrow()
            end
        end
    end

    output = open(output_filename, "w")
    print(output,
        """
        <!DOCTYPE html>
        <html>
        <meta charset="utf-8" />
        <head>
            <title>Gadfly Test Plots</title>
        </head>
        <body>
        <script src="$(Compose.snapsvgjs)"></script>
        <script src="$(Gadfly.gadflyjs)"></script>
        <div style="width:900; margin:auto; text-align: center; font-family: sans-serif; font-size: 20pt;">
        """)

    for (name, width, height) in tests
        if !in(name, whitelist)
            continue
        end

        println(output, "<p>", name, "</p>")
        print(output, """<div id="$(name)"><object type="image/svg+xml" data="$(name).js.svg"></object></div>""")
        print(output, """<img width="450px" src="$(name).svg">""")
        print(output, """<img width="450px" src="$(name).png">\n""")
    end

    print(output,
        """
        </div>
        </body>
        """)

    close(output)
end

if prev_theme !== nothing
    ENV["GADFLY_THEME"] = prev_theme
end


run_tests("output/test.html")
#@time run_tests("output/test.html")
#@profile run_tests("output/test.html")
#Profile.print()
