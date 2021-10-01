###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module CommandLine

###=============================================================================
### Exports
###=============================================================================

export main

###=============================================================================
### Imports
###=============================================================================

using Base: @kwdef
import Base: show, getindex, get
using ArgParse: @add_arg_table!, add_arg_table!, ArgParseSettings, parse_args

###=============================================================================
### Implementation
###=============================================================================

###-----------------------------------------------------------------------------
### Types
###-----------------------------------------------------------------------------

##------------------------------------------------------------------------------
## Command
##------------------------------------------------------------------------------

@kwdef struct Command{command}
    arguments::Dict{String, Any} = Dict{String, Any}()
end

function Command(command::String)
    return Command{Symbol(command)}()
end

command_string(::Type{Command{command}}) where {command} = string(command)

function Base.show(io::IO, command::Command{C}) where {C}
    println(io, "Command{$C}:")
    for (key, value) in command.arguments
        println(io, "  $key => $value")
    end
    return nothing
end

macro cmd_str(command)
    return :(Command{Symbol($command)})
end

function getindex(command::Command, key::String)
    return getindex(command.arguments, key)
end

function get(command::Command, key::String, default)
    return get(command.arguments, key, default)
end

##------------------------------------------------------------------------------
## Settings
##------------------------------------------------------------------------------

const Settings = ArgParseSettings

###-----------------------------------------------------------------------------
### Command API
###-----------------------------------------------------------------------------

function compile!(::Settings, command::Command{C}) where {C}
    @error "Missing `compile` method for Command{$C}."
    throw(MethodError(compile, (Type{Settings}, Command{C})))
end

function execute(command::Command{C}) where{C}
    @error "Missing `execute` method for Command{$C}."
    throw(MethodError(execute, (Command{C},)))
end

###-----------------------------------------------------------------------------
### Main
###-----------------------------------------------------------------------------

# TODO exception handling
function main(raw_arguments::Vector{String})
    command::Command = parse(Command, raw_arguments)
    execute(command)::Int |> exit
end

function parse(::Type{Command}, arguments::Vector{String})::Command
    settings = Settings(prog = PROGRAM_FILE)
    for cmd in command_strings()
        add_arg_table!(settings, cmd, Dict(:action => :command))
        compile!(settings[cmd], Command(cmd))
    end
    parsed_args = parse_args(arguments, settings)
    cmd = parsed_args["%COMMAND%"]
    command::Command = Command(cmd)
    merge!(command.arguments, parsed_args[cmd])
    return command
end

function command_strings()::Vector{String}
    return [command_string(m.sig.types[2])
            for m in methods(execute)
            if isconcretetype(m.sig)]
end

end # module
