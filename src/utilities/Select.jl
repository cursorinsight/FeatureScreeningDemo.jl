###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

###=============================================================================
### Exports
###=============================================================================

export select, Selector, All, Idxs, Screen

###=============================================================================
### Imports
###=============================================================================

using FeatureScreening: FeatureSet, Selector, screen
import FeatureScreening: select

using Base: @kwdef

###=============================================================================
### Implementation
###=============================================================================

@doc """
    select(feature_set::FeatureSet, selector::Selector)::FeatureSet

# Description
Select by a specific `selector` from to given `feature set`.

# Parameters
- `feature_set`
- `selector`
""" select

"""
    All()

Select all of the given set. This function is designed to fit the other
selectors.
"""
struct All <: Selector end

function select(feature_set::FeatureSet, ::All)::FeatureSet
    return feature_set
end

"""
    Idxs(indices...)

Select simply by the given `indices`. The `indices` could be different kind of
interval markers such as ':', [1, 2, 5] or 4:6.
"""
struct Idxs <: Selector
    indices::Tuple
    function Idxs(indices...)
        return new(indices)
    end
end

function select(set, selector::Idxs)
    return set[selector.indices...]
end

"""
    Screen(; reduced_size::Integer, step_size::Integer, config::NamedTuple)

Select by the given screening configurations, `reduced_size`, `step_size`,
`config`.
"""
@kwdef struct Screen <: Selector
    reduced_size::Integer
    step_size::Integer
    config::NamedTuple
end

function select(feature_set::FeatureSet, selector::Screen)::FeatureSet
    return screen(feature_set;
                  selector.reduced_size,
                  selector.step_size,
                  selector.config)
end
