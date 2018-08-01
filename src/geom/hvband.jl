"""
    Geom.band[(; orientation=:vertical)]

Draw bands across the plot canvas with a horizontal span specifed by `xmin` and `xmax` if `orientation` is `:vertical`, or a vertical span specified by `ymin` and `ymax` if the `orientation` is `:horizontal`.

This geometry is equivalent to [`Geom.rect`](@ref) with [`Stat.band`](@ref).
"""
band(;orientation=:vertical) = RectangularGeometry(Stat.band(orientation))


"""
    Geom.hband[()]

Draw horizontal bands across the plot canvas with a vertical span specified by `ymin` and `ymax` aesthetics.

This geometry is equivalent to [`Geom.band`](@ref) with `orientation` set to `:vertical`.
"""
hband() = band(orientation=:horizontal)


"""
    Geom.vband[()]

Draw vertical bands across the plot canvas with a horizontal span specified by `xmin` and `xmax` aesthetics.

This geometry is equivalent to [`Geom.band`](@ref).
"""
const vband = band
