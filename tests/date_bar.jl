
using Gadfly,  Datetime

dates = Array(Date{ISOCalendar},40)
dates[1] = today()
for i=2:length(dates)
    dates[i] = today()+days(i)
end

plot(x=dates,y=sort(rand(40)*40),Geom.bar)


