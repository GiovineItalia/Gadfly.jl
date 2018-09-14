using Gadfly, DataFrames

set_default_plot_size(6inch, 3inch)

#demonstration of BLE channel hopping noise avoidance
function gaussian(x, mu, sigmaSquared)
    sigma = sqrt(sigmaSquared)
    1 / (sigma * sqrt(2 * pi)) * exp(-1.0 * ((x - mu) ^ 2) / (2.0 * (sigmaSquared) ))
end

WiFiFreqs = [2412, 2437, 2462]
BLEFreqs = vcat(2404:2:2424, 2428:2:2478)
x = [2400:1:2500;]

WiFiPlots = [2.0 * gaussian(ix, iy, 40.0) for ix=x, iy=WiFiFreqs]

BLEValues = [ (findfirst(isequal(ix), BLEFreqs) !== nothing ? 0.127 : 0/0) for ix=x]
BLEChannels = [something(findfirst(isequal(ix), BLEFreqs),0) for ix=x]
BLEChannelStrs = [(ix < 10) ? "0$ix" : "$ix" for ix=BLEChannels]
df = DataFrame(frequency=x, value=BLEValues, channel=BLEChannels)

plot(
    layer(x=x, y=WiFiPlots[:, 1], Geom.line, Theme(default_color=colorant"#95a5b5", line_width=7px)),
    layer(x=x, y=WiFiPlots[:, 2], Geom.line, Theme(default_color=colorant"#95a5b5", line_width=7px)),
    layer(x=x, y=WiFiPlots[:, 3], Geom.line, Theme(default_color=colorant"#95a5b5", line_width=7px)),
    layer(df, x="frequency", y="value", color="channel", Geom.bar,
          Theme(default_color=colorant"#ff8585", point_size=5px)),
     Scale.y_sqrt
)
