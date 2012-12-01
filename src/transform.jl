

type Transform
    var::Symbol     # variables to which the transform is applied
    f::Function     # transform function
    finv::Function  # f's inverse
    label::Function # produce a string given some value f(x)
end


# Constructors


function IdenityTransform(var::Symbol)
    Transform(var, identity, identity, fmt_float)
end


function Log10Transform(var::Symbol)
    Transform(var,
              log10,
              x -> 10^x,
              x -> @sprintf("10<sup>%s</sup>", fmt_float(x)))
end


function LnTransform(var::Symbol)
    Transform(var,
              log,
              exp,
              x -> @sprintf("e<sup>%s</sup>", fmt_float(x)))
end


function AsinhTransform(var::Symbol)
    Transform(var,
              x -> real(asinh(x + 0im)),
              sinh,
              x -> fmt_float(sinh(x)))
end


function SqrtTransform(var::Symbol)
    Transform(var,
              sqrt,
              x -> 2^x,
              x -> fmt_float(sqrt(x)))
end


# Presets


const transform_x_identity = IdenityTransform(:x)
const transform_y_identity = IdenityTransform(:y)
const transform_x_log10    = Log10Transform(:x)
const transform_y_log10    = Log10Transform(:y)
const transform_x_ln       = LnTransform(:x)
const transform_y_ln       = LnTransform(:y)
const transform_x_asinh    = AsinhTransform(:x)
const transform_y_asinh    = AsinhTransform(:y)
const transform_x_sqrt     = SqrtTransform(:x)
const transform_y_sqrt     = SqrtTransform(:y)


# Application


# Apply a series of transforms.
#
# Args:
#   trans: Transforms to be applied in order.
#   aess: Aesthetics to be transformed.
#
# Returns:
#   Nothing, but modifies aess.
#
function apply_transforms(trans::Vector{Transform}, aess::Vector{Aesthetics})
    for tran in trans
        for aes in aess
            if getfield(aes, tran.var) === nothing
                continue
            end

            setfield(aes, tran.var, map(tran.f, getfield(aes, tran.var)))
        end
    end
    nothing
end


