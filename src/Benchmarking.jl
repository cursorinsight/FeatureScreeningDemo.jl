###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Benchmarking

###=============================================================================
### Exports
###=============================================================================

export benchmark, measure, Measurement

###=============================================================================
### Imports
###=============================================================================

using FeatureScreening: FeatureSet
using FeatureScreeningDemo.Utilities: hitrate

import Base.Iterators: product

###=============================================================================
### Implementation
###=============================================================================

###-----------------------------------------------------------------------------
### Types
###-----------------------------------------------------------------------------

struct Measurement # TODO add parametric types
    config
    metrics
end

###-----------------------------------------------------------------------------
### API
###-----------------------------------------------------------------------------

function measure(config, args...)
    @error "Missing callback `measure` method."
    throw(MethodError(measure, typeof.((config, args...))))
end

function benchmark(args...; config)::Array{Measurement}
    return map(product(config)) do config
        return Measurement(config, measure(config, args...))
    end
end

const DEFAULT_FOREST_CONFIG =
    (n_subfeatures = -1,
     partial_sampling = 1.0,
     max_depth = -1,
     min_samples_leaf = 1,
     min_samples_split = 2,
     min_purity_increase = 0.01)

function measure(config::NamedTuple,
                 train::FeatureSet,
                 test::FeatureSet
                )::NamedTuple
    forest::RandomForest
    elapsed_time::Real =
        @elapsed forest = build_forest(train; config)
    accuracy::Real =
        hitrate(apply_forest(forest, features(test)), labels(test))
    return (; elapsed_time, accuracy)
end

function measure(train::FeatureSet,
                 test::FeatureSet)
    return measure(DEFAULT_FOREST_CONFIG, train, test)
end

end # module
