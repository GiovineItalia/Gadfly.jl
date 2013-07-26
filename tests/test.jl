#!/usr/bin/env julia

using Gadfly
using RDatasets

tests = [
    "points",
    "colored_points",
    "vstack",
    "hstack",
    "colored_hist",
    "stacked_discrete_histogram",
    "dodged_discrete_histogram"
]

backends = {
    "svg" => name -> SVG("$(name).svg", 6inch, 3inch),
    "d3"  => name -> D3("$(name).js",   6inch, 3inch),
    "png" => name -> PNG("$(name).png", 6inch, 3inch),
    "ps"  => name -> PS("$(name).ps",   6inch, 3inch),
    "pdf" => name -> PDF("$(name).pdf", 6inch, 3inch)
}


function run_tests()
    for test in tests
        for (backend_name, backend) in backends
            println(STDERR, "Rendering $(test) on $(backend_name) backend.")
            p = evalfile("$(test).jl")
            draw(backend(test), p)
        end
    end
end

run_tests()

