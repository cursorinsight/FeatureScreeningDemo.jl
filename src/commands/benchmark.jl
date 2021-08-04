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
using FeatureScreeningDemo.Metrics: goodness
using FeatureScreeningDemo.Benchmarking: benchmark
using FeatureScreeningDemo.Utilities: split

###=============================================================================
### Command API
###=============================================================================

function compile(::Type{Settings}, ::cmd"benchmark")::Settings
    return @add_arg_table! Settings(prog = "benchmark") begin
        "config"
        arg_type = String
        required = true
    end
end

function execute(command::cmd"benchmark")::Integer
    config::NamedTuple = get_config(command)

    @info "Start to benchmark" config

    @info "Load feature set" config[:feature_set]
    feature_set::FeatureSet = load(FeatureSet, config[:feature_set])

    (train::FeatureSet, test::FeatureSet) =
        split(feature_set; size = config[:train_size])

    @info "Benchmark" config[:config]
    benchmark(goodness,
              (train, test);
              config = config[:config],
              persist = config[:output])

    return 0
end

# TODO maybe add some structure, normalize like names and types of indexable
# things here
function get_config(command::cmd"benchmark")::NamedTuple
    cwd::String = joinpath(pwd(), dirname(command["config"]))
    config::NamedTuple = load(NamedTuple, command["config"])
    feature_set::String = joinpath(cwd, config[:feature_set])
    train_size::Real = get(config, :train_size, 0.5)
    output::String = joinpath(cwd, get(config, :output, "benchmarks"))
    config = NamedTuple(config[:config])
    return (; feature_set, train_size, config, output)
end

end # module
