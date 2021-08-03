###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Utilities

###=============================================================================
### Imports
###=============================================================================

import Base: NamedTuple

using Base.Iterators: filter
import Base.Iterators: product

###=============================================================================
### API
###=============================================================================

function hitrate(a::AbstractArray, b::AbstractArray)::Float64
    @assert size(a) == size(b)
    return count(a .== b) / length(a)
end

function NamedTuple(keys, values)
    return NamedTuple{Tuple(keys)}(values)
end

# TODO This should/could/might be lazy.
# TODO Because of the iteration over `String` in `product` causes (A) and (B).
# Maybe not necessary.
function product(kvs::NamedTuple)
    # TODO (A)
    to_be_exposed = filter(pairs(kvs)) do (k, v)
        return v isa AbstractVector
    end
    ks = first.(to_be_exposed)
    vs = last.(to_be_exposed)
    return map(product(vs...)) do vs::Tuple
        # TODO (B)
        return merge(kvs, NamedTuple(ks, vs))
    end
end

end # module
