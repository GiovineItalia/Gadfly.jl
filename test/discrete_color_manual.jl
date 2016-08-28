using Gadfly
using Colors
using Base.Test

# This should throw a MethodError, not a stackoverflow
@test_throws MethodError Scale.color_discrete_manual([RGBA(0,0,0,0.1)])

plot([sin, cos], 0, 25, Scale.color_discrete_manual("red", "purple"))
