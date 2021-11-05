##------------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------
# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/13

module __Command__demo

###=============================================================================
### Imports
###=============================================================================

# Command API
import FeatureScreeningDemo.Utilities.CommandLine: description, compile, execute

# Command compilation imports
using FeatureScreeningDemo.Utilities.CommandLine: @Cmd_str, Settings, @settings

# Command execution imports
using FeatureScreeningDemo.Utilities: now2
using FeatureScreening: FeatureSet, screen
using FeatureScreeningDemo.Utilities.Benchmarking: Benchmark, benchmark
using FeatureScreeningDemo.Metrics: goodness

###=============================================================================
### Command API
###=============================================================================

function description(::Cmd"demo")::String
    return """
    This command demonstrates most of the features of this demo application;
      1. generate a feature set,
      2. screen that,
      3. run benchmarks on
        - the original feature set,
        - the hypothetical best subset of the original feature set and
        - the screened subset.
    """
end

function compile(::Type{Settings}, ::Cmd"demo")::Settings
    return @settings
end

function execute(::Cmd"demo")::Integer
    return main()
end

###=============================================================================
### Main
###=============================================================================

const DEFAULT_SCREEN_CONFIG =
    (n_subfeatures = -1,
     partial_sampling = 1.0,
     max_depth = 10,
     min_samples_leaf = 1,
     min_samples_split = 2,
     min_purity_increase = 0.1,
     n_trees = 10)

const DEFAULT_TEST_CONFIG =
    (n_subfeatures = 8,
     partial_sampling = 1.0,
     max_depth = -1,
     min_samples_leaf = 1,
     min_samples_split = 2,
     min_purity_increase = [0.0, 0.04, 0.16],
     n_trees = [2, 4, 8, 16])

function main(;
              directory::AbstractString = "demo.$(now2())",

              # feature set arguments
              no_samples::Integer = 100,
              no_features::Integer = 128,
              label_count::Integer = 10,

              # screen arguments
              reduced_size::Integer = 16,
              step_size::Integer = 8,
              screen_config = DEFAULT_SCREEN_CONFIG,

              # benchmark arguments
              test_config = DEFAULT_TEST_CONFIG
             )::Integer
    mkpath(directory)

    # Test features
    test::FeatureSet = rand(FeatureSet, no_samples, no_features; label_count)
    # All features
    all::FeatureSet = rand(FeatureSet, no_samples, no_features; label_count)
    test_all::FeatureSet = test
    # Theoretically top features
    top::FeatureSet = all[:, (no_features-reduced_size+1):no_features]
    test_top::FeatureSet = test[:, names(top)]

    # Screen
    @info "Screen"
    screened::FeatureSet =
        screen(all; reduced_size, step_size, config = screen_config)
    test_screened::FeatureSet = test[:, names(screened)]

    let config::NamedTuple = test_config
        benchmark(goodness,
                  (all, test_all);
                  config,
                  description = "all",
                  persist = directory)

        benchmark(goodness,
                  (top, test_top);
                  config,
                  description = "top",
                  persist = directory)

        benchmark(goodness,
                  (screened, test_screened);
                  config,
                  description = "screened",
                  persist = directory)
    end

    return 0
end

end # module
