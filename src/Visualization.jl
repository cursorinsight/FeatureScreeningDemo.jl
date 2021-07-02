###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Visualization

###=============================================================================
### Imports
###=============================================================================

import PlotlyJS: plot
using FeatureScreening.Types: FeatureSet, labels, features
using PlotlyJS: scatter

###=============================================================================
### Implementation
###=============================================================================

function plot(feature_set::FeatureSet{L}) where {L}
    # TODO remove if feature set has information about the labels
    # Collect label indices
    idxs = Dict{L, Vector{Int}}()
    foldl(enumerate(labels(feature_set)); init = idxs) do idxs, (idx, label)
        push!(get!(idxs, label, Int[]), idx)
        return idxs
    end

    # TODO never use Plotly again
    return plot([let x = [fill.(1:size(feature_set, 2), length(idxs))...;],
                     y = reshape(features(feature_set[idxs, :]), :)
                     scatter(x = x, y = y, name = label, mode = "markers")
                 end
                 for (label, idxs) in sort!(collect(idxs); by = first)])
end

end # module
