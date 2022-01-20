##-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module __Command__benchmark

###=============================================================================
### Imports
###=============================================================================

# Command API
import FeatureScreeningDemo.Utilities.CommandLine: description, compile, execute

# Command compilation imports
using FeatureScreeningDemo.Utilities.CommandLine: @Cmd_str, Settings, @settings
#
# Command execution imports
using FeatureScreening: load, FeatureSet
using FeatureScreening.Utilities: Maybe
using FeatureScreeningDemo.Metrics: goodness
using FeatureScreeningDemo.Utilities.Benchmarking: benchmark
using FeatureScreeningDemo.Utilities: split, @pwd_str

###=============================================================================
### Command API
###=============================================================================

function description(::Cmd"benchmark")::String
    return """
    This command benchmarks a feature set.
    """
end

function compile(::Type{Settings}, ::Cmd"benchmark")::Settings
    return @settings begin
        "--config"
        help = "path of the benchmark configuration"
        arg_type = String
        required = false
        default = ""

        "--output"
        help = "directory to store the results"
        arg_type = String
        required = false

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

# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/12
function execute(command::Cmd"benchmark")::Integer
    arguments::NamedTuple = get_arguments(command)

    @info "Start to benchmark" arguments

    train::FeatureSet = load(FeatureSet, arguments[:train])

    (train, test::FeatureSet) =
        if has_test_set(arguments)
            (train, load(FeatureSet, arguments[:test]))
        else
            split(train; size = arguments[:config][:train_size])
        end

    @info "Benchmark" arguments[:config][:benchmark]
    benchmark(goodness,
              (train, test);
              config = arguments[:config][:benchmark],
              persist = arguments[:output])

    return 0
end

function get_arguments(command::Cmd"benchmark")::NamedTuple
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

    config::NamedTuple = load_config(command)
    output::String =
        let output = command["output"]
            if !(output isa Nothing)
                pwd"$output"
            else
                "benchmarks"
            end
        end

    return (; train, test, config, output)
end

const DEFAULT_CONFIG = (; train_size = 0.8, config = (;))

function load_config(command::Cmd"benchmark")::NamedTuple
    config::NamedTuple = if ispath(command["config"])
        load(NamedTuple, command["config"])
    else
        (;)
    end
    return merge(DEFAULT_CONFIG, config)
end

function has_test_set(arguments::NamedTuple)::Bool
    return has_test_set(arguments[:test])
end

function has_test_set(::Nothing)::Bool
    return false
end

function has_test_set(path::AbstractString)::Bool
    return isfile(path)
end

end # module
