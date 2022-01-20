##------------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------
# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/13

module __Command__tbd

###=============================================================================
### Imports
###=============================================================================

# Command API
import FeatureScreeningDemo.Utilities.CommandLine: compile, description, execute

# Command compilation imports
using FeatureScreeningDemo.Utilities.CommandLine: @Cmd_str, @settings, Settings

# Command execution imports
using FeatureScreening: FeatureSet, load, names, save, screen
using FeatureScreening.Utilities: Maybe
using FeatureScreeningDemo.Metrics: goodness
using FeatureScreeningDemo.Utilities.Benchmarking: benchmark
using FeatureScreeningDemo.Utilities: @pwd_str, @path_str, now2, split
using FeatureScreeningDemo.Visualization: plot

using PlotlyJS: savefig

###=============================================================================
### Command API
###=============================================================================

function description(::Cmd"tbd")::String
    return """
    This command benchmarks a feature set, screens that and benchmarks again the
    screened subset. It saves all measurements into the same dictionary.
    """
end

function compile(::Type{Settings}, ::Cmd"tbd")::Settings
    return @settings begin
        "--benchmark_config"
        help = "path of the benchmark configuration"
        arg_type = String
        required = false
        default = ""

        "--screen_config"
        help = "path of the screen configuration"
        arg_type = String
        required = false
        default = ""

        "train"
        help = "path of training feature set"
        arg_type = String
        required = true

        "test"
        help = "path of testing feature set"
        arg_type = String
        required = false
    end
end

function execute(command::Cmd"tbd")::Integer
    (train::String,
     test::Maybe{String},
     benchmark_config::NamedTuple,
     screen_config::NamedTuple) = get_arguments(command)

    output::String = "tbd.$(now2())"
    mkpath(output)

    @info "Start tbd" train test output benchmark_config screen_config

    benchmark_train::FeatureSet = load(FeatureSet, train)

    (benchmark_train, benchmark_test::FeatureSet) =
        if has_test_set(test)
            (benchmark_train, load(FeatureSet, test))
        else
            split(benchmark_train; size = benchmark_config[:train_size])
        end

    @info "Benchmark the original feature set"
    b = benchmark(goodness,
                  (benchmark_train, benchmark_test);
                  config = benchmark_config[:benchmark],
                  persist = output)

    p1 = plot(b.measurements;
              group_by = :n_trees,
              x = :elapsed_time,
              y = :accuracy)

    savefig(p1, path"$output/benchmark_$(now2()).png"; format = "png")

    (screen_train, screen_test::FeatureSet) =
        split(benchmark_train; size = 1 - screen_config[:test_size])
    
    @info "Screen the original feature set" screen_config[:screen]
    screened_train::FeatureSet = screen(screen_train; screen_config[:screen]...)
    screened_test = screen_test[:, names(screened_train)]

    save(screened_train; directory = output)
    if !isempty(screened_test)
        save(screened_test; directory = output)
    end

    @info "Benchmark the screened subset" benchmark_config[:screened]
    screened_benchmark = benchmark(goodness,
              (screened_train, screened_test);
              config = benchmark_config[:screened],
              persist = output)

    p2 = plot(screened_benchmark.measurements;
              group_by = :n_trees,
              x = :elapsed_time,
              y = :accuracy)

    savefig(p2, path"$output/screened_benchmark_$(now2()).png"; format = "png")

    return 0
end

###-----------------------------------------------------------------------------
### Internal functions
###-----------------------------------------------------------------------------

const DEFAULT_BENCHMARK_CONFIG = (; train_size = 0.8, config = (;))
const DEFAULT_SCREEN_CONFIG = (; test_size = 0.0, screen = (;))

function get_arguments(command::Cmd"tbd")::NamedTuple
    train::String = command["train"]
    train = pwd"$train"
    test::Maybe{String} =
        let test = command["test"]
            if !(test isa Nothing)
                pwd"$test"
            else
                nothing
            end
        end

    benchmark_config::NamedTuple = load_config(command,
                                               "benchmark_config",
                                               DEFAULT_BENCHMARK_CONFIG)
    screen_config::NamedTuple = load_config(command,
                                            "screen_config",
                                            DEFAULT_SCREEN_CONFIG)

    return (; train, test, benchmark_config, screen_config)
end

function load_config(command::Cmd"tbd",
                     option::String,
                     default_config::NamedTuple
                    )::NamedTuple
    config::NamedTuple = if ispath(command[option])
        load(NamedTuple, command[option])
    else
        (;)
    end

    return merge(default_config, config)
end

function has_test_set(::Nothing)::Bool
    return false
end

function has_test_set(path::AbstractString)::Bool
    return isfile(path)
end

end # module
