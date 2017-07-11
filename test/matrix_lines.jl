
using Gadfly

# wide-form plotting of matrices

n = 20
m = 40
X = randn(m, n) * diagm(1:n)

plot(X, x=Row.index, y=Col.value, color=Col.index, Geom.line)
