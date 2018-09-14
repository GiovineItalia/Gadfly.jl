using Gadfly, LinearAlgebra

# wide-form plotting of matrices

set_default_plot_size(6inch, 4inch)

n = 20
m = 40
X = randn(m, n) * Matrix(Diagonal(1:n))

plot(X, x=Row.index, y=Col.value, color=Col.index, Geom.line)
