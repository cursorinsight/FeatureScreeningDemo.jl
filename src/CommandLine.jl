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
import FeatureScreeningDemo.Utilities: parse
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

function name(::Command{command})::String where {command}
    return String(command)
end

function name(::Type{Command{command}})::String where {command}
    return String(command)
end

##------------------------------------------------------------------------------
## Settings
##------------------------------------------------------------------------------

const Settings = ArgParseSettings

###-----------------------------------------------------------------------------
### Main
###-----------------------------------------------------------------------------

# TODO remove or revamp
# TODO rename or something, this function returns strings
function COMMANDS()::Vector{String}
    return [m.sig.types[2].parameters |> only |> string
            for m in methods(execute)
            if isconcretetype(m.sig)] |> sort
end

function main(arguments::Vector{String})
    try
        arguments |> parse(Command) |> execute |> exit
    catch exception
        @error "Something went wrong" exception
        rethrow(exception)
        # TODO replace with some built-in function
        println("Usage: $(PROGRAM_FILE) $(join(COMMANDS(), '|')) [-h] ...")
        exit(1)
    end
end

function parse(::Type{Command}, raw_arguments::Vector{String})::Command
    @assert !isempty(raw_arguments)
    (raw_command::String, raw_arguments...) = raw_arguments
    @assert raw_command in COMMANDS()
    command = Command(raw_command)
    settings::Settings = compile(Settings, command)
    arguments = parse_args(raw_arguments, settings)
    merge!(command.arguments, arguments)
    return command
end

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

end # module
