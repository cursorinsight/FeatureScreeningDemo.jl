###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Visualization

###=============================================================================
### Imports
###=============================================================================
using FeatureScreening: FeatureSet
using FeatureScreening.Types: labels, names, features
import PlotlyJS: plot
using PlotlyJS: scatter

# TODO plot(one sample) (how? why?)

MAX_MARKERS = 30000
function plot(feature_set::FeatureSet)
    # Rearrange matrix:
    # - each label gets an own column
    # - the features are serialized into it
    # (L1) (L2) ...
    #  F1   F1  ...
    #  F2   F2  ...
    #  ....
    #  FN   FN  ...
    #  F1   F1  ...
    #  ...  ...
    _features = features(feature_set)
    _labels = labels(feature_set)
    (n_samples, n_features) = size(_features)
    if n_samples * n_features > MAX_MARKERS
        @warn "Too many samples for plot, will only show a part of the samples"
        n_samples = MAX_MARKERS ÷ n_features
    end
    unique_labels = unique(_labels)
    n_samples_per_label = n_samples ÷ length(unique_labels)
    if n_samples_per_label == 0
        @warn "Cannot plot all features, there are too many"
        return nothing
    end
    label_idxs::Dict{eltype(_labels),Int} =
        Dict(name => i for (i, name) in enumerate(unique_labels))
    x = repeat(1:n_features, n_samples_per_label)
    samples = Matrix{eltype(_features)}(
        undef,
        n_samples_per_label * n_features,
        length(unique_labels)
    )
    samples_per_label = zeros(Int, length(unique_labels))
    for (label, features) in feature_set
        li = label_idxs[label]
        if samples_per_label[li] < n_samples_per_label
            offset = samples_per_label[li] += 1
            samples[(offset-1)*n_features+1:offset*n_features, li] = features'
        end
    end
    return plot([
        scatter(;
            x,
            y = samples[:, i],
            name = unique_labels[i],
            mode = "markers",
        ) for i in eachindex(unique_labels)
    ])
end

end # module
