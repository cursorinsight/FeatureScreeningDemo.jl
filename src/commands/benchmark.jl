##-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module CmdBenchmark

###=============================================================================
### Imports
###=============================================================================

# Command API
import FeatureScreeningDemo.CommandLine: compile, execute

# Command compilation imports
using FeatureScreeningDemo.CommandLine: Settings, @cmd_str, @add_arg_table!
#
# Command execution imports
using FeatureScreening: load, FeatureSet
using FeatureScreening.Utilities: Maybe
using FeatureScreeningDemo.Metrics: goodness
using FeatureScreeningDemo.Benchmarking: benchmark
using FeatureScreeningDemo.Utilities: split, @pwd_str

###=============================================================================
### Command API
###=============================================================================

function compile(::Type{Settings}, ::cmd"benchmark")::Settings
    return @add_arg_table! Settings(prog = "benchmark") begin
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

function execute(command::cmd"benchmark")::Integer
    arguments::NamedTuple = get_arguments(command)

    @info "Start to benchmark" arguments

    train::FeatureSet = load(FeatureSet, arguments[:train])

    (train, test::FeatureSet) =
        if has_test_set(arguments)
            (train, load(FeatureSet, arguments[:test]))
        else
            split(train; size = arguments[:config][:train_size])
        end

    @info "Benchmark" arguments[:config][:config]
    benchmark(goodness,
              (train, test);
              config = arguments[:config][:config],
              persist = arguments[:output])

    return 0
end

# TODO maybe add some structure, normalize like names and types of indexable
# things here, add some schema maybe
function get_arguments(command::cmd"benchmark")::NamedTuple
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

function has_test_set(arguments::NamedTuple)::Bool
    return has_test_set(arguments[:test])
end

function has_test_set(::Nothing)::Bool
    return false
end

# TODO maybe add some more checker, like is that a valid feature set?
function has_test_set(path::AbstractString)::Bool
    return isfile(path)
end

const DEFAULT_CONFIG = (; train_size = 0.8, config = (;))

function load_config(command::cmd"benchmark")::NamedTuple
    config::NamedTuple = if ispath(command["config"])
        load(NamedTuple, command["config"])
    else
        (;)
    end
    return merge(DEFAULT_CONFIG, config)
end

end # module
