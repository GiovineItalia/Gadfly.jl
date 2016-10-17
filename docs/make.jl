using Documenter, Gadfly

load_dir(x) = map(file -> joinpath("lib", x, file), readdir(joinpath(Base.source_dir(), "src", "lib", x)))

makedocs(
    modules = [Gadfly],
    clean = false,
    format = :html,
    sitename = "Gadfly.jl",
    pages = Any[
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "Manual" => Any[
            "Plotting" => "man/plotting.md",
            "Stacks & Layers" => "man/layers.md",
            "Backends" => "man/backends.md",
            "Themes" => "man/themes.md",
        ],
        "Library" => Any[
            "Rendering Pipeline" => "lib/dev_pipeline.md",
            hide("Geometries" => "lib/geometries.md", load_dir("geoms")),
            hide("Guides" => "lib/guides.md", load_dir("guides")),
            hide("Statistics" => "lib/stats.md", load_dir("stats")),
            hide("Coords" => "lib/coords.md", load_dir("coords")),
            hide("Scales" => "lib/scales.md", load_dir("scales")),
        ]
    ]
)

deploydocs(
    repo   = "github.com/GiovineItalia/Gadfly.jl.git",
    julia  = "0.5",
    osname = "linux",
    deps = nothing,
    make = nothing,
    target = "build",
)
