


@varset Data begin
    x
    y
    z
    xmin
    xmax
    ymin
    ymax
    xintercept
    yintercept
    middle
    lower_hinge
    upper_hinge
    lower_fence
    upper_fence
    xgroup
    ygroup
    xtick
    ytick
    xtick_labels
    ytick_labels
    xviewmin
    xviewmax
    yviewmin
    yviewmax
    size
    shape
    xsize
    ysize
    color
    group
    label
    func
    titles, Dict{Symbol, String}, Dict{Symbol, String}()
end



# Produce a new Data instance chaining the values of one or more others.
#
# The bound values in the returned Data instance are chain iterators which will
# iterate through the values contained in all the given Data instances.
#
# Args:
#  ds: Some Data instances.
#
# Returns:
#   A new Data instance.
#
function chain(ds::Data...)
    chained_data = Data()
    for name in fieldnames(Data)
        vs = Any[getfield(d, name) for d in ds]
        vs = Any[v for v in filter(issomething, vs)]
        if isempty(vs)
            setfield!(chained_data, name, nothing)
        else
            setfield!(chained_data, name, Iterators.chain(vs...))
        end
    end

    chained_data
end


function show(io::IO, data::Data)
    maxlen = 0
    print(io, "Data(")
    for name in fieldnames(Data)
        if getfield(data, name) != nothing
            print(io, "\n  ", string(name), "=")
            show(io, getfield(data, name))
        end
    end
    print(io, "\n)\n")
end

