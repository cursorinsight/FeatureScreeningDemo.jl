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
using FeatureScreening: load, FeatureSet, screen, save, names
using FeatureScreeningDemo.Utilities: split, @path_str

###=============================================================================
### Command API
###=============================================================================

function compile(::Type{Settings}, ::cmd"screen")::Settings
    return @add_arg_table! Settings(prog = "screen") begin
        "--config"
        help = "path of the screen configuration"
        arg_type = String
        required = false
        default = ""

        "--output"
        help = "directory to store the results"
        arg_type = String
        required = false
        default = ""

        "path"
        help = "path of the feature set"
        arg_type = String
        required = true
    end
end

function execute(command::cmd"screen")::Integer
    (path::String, into::String, config::NamedTuple) = get_arguments(command)

    feature_set::FeatureSet = load(FeatureSet, path)
    (feature_set, test::FeatureSet) =
        split(feature_set; size = 1 - config[:test_size])

    @info "Screen" path into config feature_set test

    screened::FeatureSet = screen(feature_set; config[:screen]...)
    test = test[:, names(screened)]

    @info "Save results" into screened test

    save(screened; directory = into)
    if !isempty(test)
        save(test; directory = into)
    end

    return 0
end

# TODO maybe add some structure, normalize names and types of indexable
# things here
function get_arguments(command::cmd"screen")::Tuple
    cwd::String = pwd()
    path::String = command["path"]
    to::String = get(command, "to", dirname(path))
    path = path"$cwd/$path"
    to = path"$cwd/$to"

    config::NamedTuple = load_config(command)
    return (path, to, config)
end

const DEFAULT_CONFIG = (; test_size = 0.0, screen = (;))

function load_config(command::cmd"screen")::NamedTuple
    config::NamedTuple = if ispath(command["config"])
        load(NamedTuple, command["config"])
    else
        (;)
    end
    return merge(DEFAULT_CONFIG, config)
end

end # module
