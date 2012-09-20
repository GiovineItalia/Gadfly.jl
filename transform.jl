

type Transform
    vars::Vector{Symbol} # variables to which the transform is applied
    f::Function          # transform function
    finv::Function       # f's inverse
    label::Function      # produce a string given some value f(x)
end


# Constructors


function IdenityTransform(vars::Symbol...)
    Transform(vars, identity, identity, fmt_float)
end


function Log10Transform(vars::Symbol...)
    Transform(vars,
              log10,
              x -> 10^x,
              x -> @sprintf("10<sup>%s</sup>", fmt_float(x)))
end


function LnTransform(vars::Symbol...)
    Transform(vars,
              log,
              exp,
              x -> @sprintf("e<sup>%s</sup>", fmt_float(x)))
end


function AsinhTransform(vars::Symbol...)
    Transform(vars,
              x -> real(asinh(x + 0im)),
              sinh,
              x -> fmt_float(sinh(x)))
end


function SqrtTransform(vars::Symbol...)
    Transform(vars,
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




# Is this what we want? How are transforms used?  First, they are applied to
# aesthetics, then statistics are applied. The xticks and yticks statistics
# choose ticks based on the scaled data, then they have to "detransform"
# to choose labels. So, the question is, how does detransforming work?




