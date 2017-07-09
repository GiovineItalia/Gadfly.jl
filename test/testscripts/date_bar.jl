using Gadfly, Base.Dates

set_default_plot_size(6inch, 3inch)

dates = Array{Date}(40)
dates[1] = today()
for i=2:length(dates)
    dates[i] = today()+Day(i)
end

plot(x=dates,y=sort(rand(40)*40),Geom.bar)
