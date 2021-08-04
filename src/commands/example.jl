##-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module CmdExample

###=============================================================================
### Imports
###=============================================================================

# Command API
import FeatureScreeningDemo.CommandLine: compile, execute

# Command compilation imports
using FeatureScreeningDemo.CommandLine: Settings, @cmd_str, @add_arg_table!

# Command execution imports
using FeatureScreeningDemo.Utilities: now2
using FeatureScreening: FeatureSet, screen
using FeatureScreeningDemo.Benchmarking: Benchmark, benchmark
using FeatureScreeningDemo.Metrics: goodness

###=============================================================================
### Command API
###=============================================================================

function compile(::Type{Settings}, ::cmd"example")::Settings
    return @add_arg_table! Settings(prog = "example") begin
    end
end

function execute(::cmd"example")::Integer
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
     n_trees = 100)

const DEFAULT_TEST_CONFIG =
    (n_subfeatures = 16,
     partial_sampling = 1.0,
     max_depth = -1,
     min_samples_leaf = 1,
     min_samples_split = 2,
     min_purity_increase = [0.0, 0.01, 0.02, 0.04, 0.08, 0.16],
     n_trees = [25, 50, 100, 200, 400])

# TODO create proper configuration from commandline and move this function into
# the `execute` function directry
# TODO replace this randomly generated feature set with maybe a "synthetic data"
function main(;
              directory::AbstractString = "demo.$(now2())",

              # feature set arguments
              no_samples::Integer = 300,
              no_features::Integer = 256,
              label_count::Integer = 10,

              # screen arguments
              reduced_size::Integer = 32,
              step_size::Integer = 32,
              config = DEFAULT_SCREEN_CONFIG,

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
    screened::FeatureSet = screen(all; reduced_size, step_size, config)
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

        # TODO add plotting
    end

    return 0
end

end # module
