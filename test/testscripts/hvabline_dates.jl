using Gadfly, Dates

dates = [Date("2017-08-07"), Date("2017-08-08"), Date("2017-08-09")]
date = [Date("2017-08-08")]
hstack(
    plot(y=dates, Geom.point, yintercept=date, Geom.hline),
    plot(x=dates, Geom.point, xintercept=date, Geom.vline) )
