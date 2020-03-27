using Gadfly, MarketData

set_default_plot_size(1920px, 1080px)

ta = ohlc[1:50]
plot(
    x     = timestamp(ta),
    open  = values(ta.Open),
    high  = values(ta.High),
    low   = values(ta.Low),
    close = values(ta.Close),
    Geom.candlestick,
    Scale.color_discrete_manual("green", "red"))
