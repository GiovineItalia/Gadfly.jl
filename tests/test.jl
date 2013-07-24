#!/usr/bin/env julia

using Gadfly
using RDatasets

tests = [
    "points",
    "colored_points",
    "vstack",
    "hstack",
]

backends = {
    "svg" => name -> SVG("$(name).svg", 8inch, 6inch),
    "d3"  => name -> D3("$(name).js",   8inch, 6inch),
    "png" => name -> PNG("$(name).png", 8inch, 6inch),
    "ps"  => name -> PS("$(name).ps",   8inch, 6inch),
    "pdf" => name -> PDF("$(name).pdf", 8inch, 6inch)
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

