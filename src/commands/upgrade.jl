###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

# TODO remove ASAP
module CmdUpgrade

###=============================================================================
### Imports
###=============================================================================

### Command API
import FeatureScreeningDemo.CommandLine: compile, execute

## Command compilation
using FeatureScreeningDemo.CommandLine: Settings, @cmd_str, @add_arg_table!

## Command execution
using FeatureScreening.Types: upgrade!, FeatureSet
using FeatureScreeningDemo.Utilities: @path_str

###=============================================================================
### Command API
###=============================================================================

function compile(::Type{Settings}, ::cmd"upgrade")::Settings
    return @add_arg_table! Settings(prog = "upgrade") begin
        "path"
        help = "path of the feature set"
        arg_type = String
        required = true
    end
end

function execute(command::cmd"upgrade")::Integer
    cwd::String = pwd()
    path::String = command["path"]
    upgrade!(FeatureSet, path"$cwd/$path")
    return 0
end

end # module
