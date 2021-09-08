###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module CmdScreen

###=============================================================================
### Imports
###=============================================================================

# Command API
import FeatureScreeningDemo.CommandLine: compile, execute

# Command compilation imports
using FeatureScreeningDemo.CommandLine: Settings, @cmd_str, @add_arg_table!
#
# Command execution imports
using FeatureScreening: load, FeatureSet, screen, save
using FeatureScreeningDemo.Utilities: split, now2

###=============================================================================
### Command API
###=============================================================================

function compile(::Type{Settings}, ::cmd"screen")::Settings
    return @add_arg_table! Settings(prog = "screen") begin
        "config"
        arg_type = String
        required = true
    end
end

function execute(command::cmd"screen")::Integer
    config::NamedTuple = get_config(command)

    feature_set::FeatureSet = load(FeatureSet, config[:feature_set])
    (to_be_screened::FeatureSet, test::FeatureSet) =
        split(feature_set; size = 1 - config[:test_size])

    screened::FeatureSet =
        screen(to_be_screened;
               step_size = config[:step_size],
               reduced_size = config[:reduced_size],
               config = config[:config])

    save(config[:output], screened)

    return 0
end

# TODO maybe add some structure, normalize like names and types of indexable
# things here
function get_config(command::cmd"screen")::NamedTuple
    cwd::String = joinpath(pwd(), dirname(command["config"]))
    config::NamedTuple = load(NamedTuple, command["config"])
    feature_set::String = joinpath(cwd, config[:feature_set])
    test_size::Real = get(config, :test_size, 0.5)
    step_size::Real = config[:step_size]
    reduced_size::Real = get(config, :reduced_size, step_size)
    output::String =
        joinpath(cwd, get(config, :output, "$feature_set.screened.$(now2())"))
    config = NamedTuple(config[:config])
    return (; feature_set, test_size, step_size, reduced_size, config, output)
end

end # module
