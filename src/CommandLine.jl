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
using ArgParse: @add_arg_table!, ArgParseSettings, parse_args

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

function compile(::Type{Settings}, command::Command{C}) where {C}
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
    @assert !isempty(arguments)
    (cmd::String, args::Vector{String}) = (arguments[1], arguments[2:end])
    command::Command = Command(cmd)
    settings::Settings = compile(Settings, command)
    merge!(command.arguments, parse_args(args, settings))
    return command
end

end # module
