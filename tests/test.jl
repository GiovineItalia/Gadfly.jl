#!/usr/bin/env julia

using Gadfly
using RDatasets

tests = [
    "points",
    "colored_points",
    "vstack",
    "hstack",
    "colored_hist"
]

backends = {
    "svg" => name -> SVG("$(name).svg", 5inch, 3inch),
    "d3"  => name -> D3("$(name).js",   5inch, 3inch),
    "png" => name -> PNG("$(name).png", 5inch, 3inch),
    "ps"  => name -> PS("$(name).ps",   5inch, 3inch),
    "pdf" => name -> PDF("$(name).pdf", 5inch, 3inch)
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

