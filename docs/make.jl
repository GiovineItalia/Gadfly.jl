using Documenter, Gadfly

load_dir(x) = map(file -> joinpath("lib", x, file), readdir(joinpath(Base.source_dir(), "src", "lib", x)))

makedocs(
    modules = [Gadfly],
    clean = false,
    format = Documenter.Formats.HTML,
    sitename = "Gadfly.jl",
    pages = Any[
        "Home" => "index.md",
        "Manual" => Any[
            "Plotting" => "man/plotting.md",
            "Stacks & Layers" => "man/layers.md",
            "Backends" => "man/backends.md",
            "Themes" => "man/themes.md",
            "Geometries" => "man/geometries.md",
            "Guides" => "man/guides.md",
            "Statistics" => "man/stats.md",
            "Coords" => "man/coords.md",
            "Scales" => "man/scales.md"
        ],
        "Library" => Any[
            "lib/dev_pipeline.md",
            "geoms" => load_dir("geoms"),
            "guides" => load_dir("guides"),
            "stats" => load_dir("stats"),
            "coords" => load_dir("coords"),
            "scales" => load_dir("scales")
        ]
    ]
)

deploydocs(
    repo   = "github.com/dcjones/Gadfly.jl.git",
    julia  = "0.5",
    osname = "linux"
)
