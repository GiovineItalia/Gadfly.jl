
module Trans

import Gadfly

type Transform <: Gadfly.TransformElement
    var::Symbol     # variables to which the transform is applied
    f::Function     # transform function
    finv::Function  # f's inverse
    label::Function # produce a string given some value f(x)
end


# Constructors


function IdenityTransform(var::Symbol)
    Transform(var, identity, identity, Gadfly.fmt_float)
end


function Log10Transform(var::Symbol)
    Transform(var,
              log10,
              x -> 10^x,
              x -> @sprintf("10<sup>%s</sup>", Gadfly.fmt_float(x)))
end


function LnTransform(var::Symbol)
    Transform(var,
              log,
              exp,
              x -> @sprintf("e<sup>%s</sup>", Gadfly.fmt_float(x)))
end


function AsinhTransform(var::Symbol)
    Transform(var,
              x -> real(asinh(x + 0im)),
              sinh,
              x -> Gadfly.fmt_float(sinh(x)))
end


function SqrtTransform(var::Symbol)
    Transform(var,
              sqrt,
              x -> 2^x,
              x -> Gadfly.fmt_float(sqrt(x)))
end


# Presets


const x_identity = IdenityTransform(:x)
const y_identity = IdenityTransform(:y)
const x_log10    = Log10Transform(:x)
const y_log10    = Log10Transform(:y)
const x_ln       = LnTransform(:x)
const y_ln       = LnTransform(:y)
const x_asinh    = AsinhTransform(:x)
const y_asinh    = AsinhTransform(:y)
const x_sqrt     = SqrtTransform(:x)
const y_sqrt     = SqrtTransform(:y)


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
function apply_transforms(trans::Vector{Gadfly.TransformElement},
                          aess::Vector{Gadfly.Aesthetics})
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

end # module Trans

