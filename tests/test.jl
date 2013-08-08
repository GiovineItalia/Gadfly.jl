#!/usr/bin/env julia

using Gadfly
using RDatasets

tests = [
    ("points",                     6inch, 3inch),
    ("function_plots",             6inch, 3inch),
    ("colored_points",             6inch, 3inch),
    ("vstack",                     6inch, 6inch),
    ("hstack",                     6inch, 3inch),
    ("colorful_hist",              6inch, 3inch),
    ("stacked_discrete_histogram", 6inch, 3inch),
    ("dodged_discrete_histogram",  6inch, 3inch),
    ("array_aesthetics",           6inch, 3inch),
    ("subplot_grid",               6inch, 3inch),
    ("subplot_grid_histogram",     6inch, 3inch)
]


backends = {
    "svg" => (name, width, height) -> SVG("$(name).svg", width, height),
    "d3"  => (name, width, height) -> D3("$(name).js",   width, height),
    "png" => (name, width, height) -> PNG("$(name).png", width, height),
    "ps"  => (name, width, height) -> PS("$(name).ps",   width, height),
    "pdf" => (name, width, height) -> PDF("$(name).pdf", width, height)
}


function run_tests()
    for (name, width, height) in tests
        for (backend_name, backend) in backends
            println(STDERR, "Rendering $(name) on $(backend_name) backend.")
            try
                p = evalfile("$(name).jl")
                draw(backend(name, width, height), p)
            catch
                println(STDERR, "FAILED!")
                rethrow()
            end
        end
    end
end

run_tests()

