using Gadfly

n=16
pts = repeat(1:n,inner=(1,n))
plot(x=pts, y=pts', color=string.(1:n*n), Theme(key_position=:none))
