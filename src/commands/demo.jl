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
using FeatureScreeningDemo.Utilities: select, Selector, All, Idxs, Screen
using FeatureScreening: FeatureSet, screen, save
using FeatureScreeningDemo.Utilities.Benchmarking: Benchmark, benchmark
using FeatureScreeningDemo.Metrics:goodness

using PlotlyJS

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
"""
    main(;
         sample_count::Integer = 100,
         feature_count::Integer = 128,
         label_count::Integer = 10,
         kwargs...
        )::Integer

The main entry point of the `demo` command with random generated train and test
feature sets.
"""
function main(;
              sample_count::Integer = 100,
              feature_count::Integer = 128,
              label_count::Integer = 10,
              kwargs...
             )::Integer

    train::FeatureSet =
        rand(FeatureSet, sample_count, feature_count; label_count)
    test::FeatureSet =
        rand(FeatureSet, sample_count, feature_count; label_count)

    return main(train, test; kwargs...)
end

"""
    main(train::FeatureSet,
         test::FeatureSet;
         reduced_size::Integer = size(train, 2) ÷ 5,
         step_size::Integer = size(train, 2) ÷ 10,
         screen_config::NamedTuple = DEFAULT_SCREEN_CONFIG,
         test_config::NamedTuple = DEFAULT_TEST_CONFIG,
         directory::AbstractString = "demo.$(now2())"
        )::Integer

The main entry point for the `demo` command. The function creates a screened
feature set based on the given `train` feature set, then run benchmarks as you
can read in the command description.
"""
function main(train::FeatureSet,
              test::FeatureSet;
              reduced_size::Integer = size(train, 2) ÷ 5,
              step_size::Integer = size(train, 2) ÷ 10,
              screen_config::NamedTuple = DEFAULT_SCREEN_CONFIG,
              test_config::NamedTuple = DEFAULT_TEST_CONFIG,
              directory::AbstractString = "demo.$(now2())"
             )::Integer
    mkpath(directory)

    # In this tuple you can find the pairs of the names and the selectors of the
    # feature sets.
    selectors =
        ["all" => All(),
         "top" => Idxs(:, names(train)[end .- (0:reduced_size - 1)]),
         "screened" => Screen(; reduced_size, step_size, config = screen_config)
        ]

    for (name, selector) in selectors
        __train::FeatureSet = select(train, selector)
        __test::FeatureSet = select(test, Idxs(:, names(__train)))

        b = benchmark(goodness,
                      (__train, __test);
                      config = test_config,
                      description = name,
                      persist = directory)

        savefig(plot(b.measurements;
                     group_by = :n_trees,
                     x = :elapsed_time,
                     y = :accuracy),
                joinpath(directory, name * "_benchmark.png");
                format = "png")
    end

    return 0
end

end # module
