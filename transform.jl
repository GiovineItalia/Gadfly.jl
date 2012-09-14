

type Transform
    f::Function     # transform function
    finv::Function  # f's inverse
    label::Function # produce a string given some value f(x)
end


const IdenityTransform = Transform(identity, identity, fmt_float)


const Log10Transform =
    Transform(log10,
              x -> 10^x,
              x -> @sprintf("10<sup>%s</sup>", fmt_float(x)))


const LnTransform =
    Transform(log,
              x -> exp(x),
              x -> @sprintf("e<sup>%s</sup>", fmt_float(x)))


const AsinhTransform =
    Transform(x -> real(asinh(x + 0im)),
              sinh,
              x -> fmt_float(sinh(x)))


const SqrtTransform =
    Transform(sqrt,
              x -> 2^x,
              x -> fmt_float(sinh(x)))


const preset_transforms =
    {("log10", :Log10Transform), ("log", :LnTransform),
     ("asinh", :AsinhTransform), ("sqrt", :SqrtTransform)}


