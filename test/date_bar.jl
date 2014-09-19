
using Gadfly

if VERSION < v"0.4-dev"
    using Datetime
else
    date = Date
    day = Dates.Day
    today = Dates.today
end

dates = Array(Date,40)
dates[1] = today()
for i=2:length(dates)
    dates[i] = today()+day(i)
end

plot(x=dates,y=sort(rand(40)*40),Geom.bar)


