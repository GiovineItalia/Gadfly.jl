using SnoopCompile

SnoopCompile.@snoop "gadfly_compiles.csv" begin
    include("runtests.jl")
end

using Gadfly

blacklist = ["__init__", "Image",
             "unpack_pango_attr_list",
             "newsurface",
             "PangoAttr",
             "update_pango_attr",
             "pango_fmt_float",
             "unpack_pango_attr",
             "pango_text_extents",
             "cairo_linecap",
             "cairo_linejoin"]

data = SnoopCompile.read("gadfly_compiles.csv")
pc, discards = SnoopCompile.parcel(data[end:-1:1,2], blacklist=blacklist)
SnoopCompile.write("snoop", pc)

