###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Metrics

###=============================================================================
### Imports
###=============================================================================

using FeatureScreening.Types: FeatureSet, features, labels
using DecisionTree: build_forest, apply_forest
using FeatureScreeningDemo.Utilities: hitrate

###=============================================================================
### API
###=============================================================================

const DEFAULT_FOREST_CONFIG =
    (n_subfeatures = -1,
     partial_sampling = 1.0,
     max_depth = -1,
     min_samples_leaf = 1,
     min_samples_split = 2,
     min_purity_increase = 0.01)

# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/16
function goodness(train::FeatureSet,
                  test::FeatureSet;
                  config::NamedTuple = DEFAULT_FOREST_CONFIG
                 )::NamedTuple
    elapsed_time::Real = @elapsed forest = build_forest(train; config)
    accuracy::Real = hitrate(apply_forest(forest, features(test)), labels(test))
    return (; elapsed_time, accuracy)
end

end # module
