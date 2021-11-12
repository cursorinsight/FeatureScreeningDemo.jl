###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------
# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/12
# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/14

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
import FeatureScreeningDemo.Utilities: parse, @assert_
using ArgParse: @add_arg_table!, ArgParseSettings, parse_args
import ArgParse: usage_string as usage

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

macro Cmd_str(command)
    return :(Command{Symbol($command)})
end

macro cmd_str(command)
    return :(Command{Symbol($command)}())
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

##------------------------------------------------------------------------------
## Exceptions
##------------------------------------------------------------------------------

abstract type CommandLineError <: Exception end

struct MissingArgument <: CommandLineError end

struct UnknownCommand <: CommandLineError
    command::String
end

abstract type CommandLineAction <: Exception end

struct ShowUsage{command <: Command} <: CommandLineAction
    command::command
end

###-----------------------------------------------------------------------------
### Command line API
###-----------------------------------------------------------------------------

function main(arguments::Vector{String})
    try
        arguments |> parse(Command) |> execute
    catch exception
        exception |> caught
    end |> exit
end

###-----------------------------------------------------------------------------
### Command API
###-----------------------------------------------------------------------------

function execute(command::Command{C}) where{C}
    @error "Missing `execute` method for Command{$C}."
    throw(MethodError(execute, (Command{C},)))
end

function compile(::Type{Settings}, command::Command{C}) where {C}
    @error "Missing `compile` method for Command{$C}."
    throw(MethodError(compile, (Type{Settings}, Command{C})))
end

function description(::Command)::String
    return ""
end

###-----------------------------------------------------------------------------
### Exception API
###-----------------------------------------------------------------------------

function caught(exception::Exception)::Int
    handle(ShowUsage(cmd"__main__"))
    rethrow(exception)
    return 1
end

function caught(action::CommandLineAction)::Int
    return handle(action)
end

function caught(::MissingArgument)::Int
    @error "Missing argument"
    handle(ShowUsage(cmd"__main__"))
    return 1
end

function caught(error::UnknownCommand)::Int
    @error "Unknown command: $(error.command)"
    handle(ShowUsage(cmd"__main__"))
    return 1
end

function handle(action::ShowUsage)::Int
    print(stderr, usage(action.command))
    return 0
end

##------------------------------------------------------------------------------
## Utilities
##------------------------------------------------------------------------------

macro settings end

macro settings()
    return :(@add_arg_table! Settings())
end

macro settings(arg_table)
    return :(@add_arg_table! Settings() $arg_table)
end

macro settings(settings, arg_table)
    return :(@add_arg_table! $settings $arg_table)
end

###-----------------------------------------------------------------------------
### Internals
###-----------------------------------------------------------------------------

function COMMANDS()::Vector{String}
    return [m.sig.types[2].parameters |> only |> string
            for m in methods(execute)
            if isconcretetype(m.sig)] |> sort
end

function parse(::Type{Command}, raw_arguments::Vector{String})::Command
    @debug "Parse command" raw_arguments

    # <program>
    @assert_ !isempty(raw_arguments) MissingArgument()

    # <program> --help
    @assert_ raw_arguments != ["-h"]  ShowUsage(cmd"__main__")
    @assert_ raw_arguments != ["--help"]  ShowUsage(cmd"__main__")

    (raw_command::String, raw_arguments...) = raw_arguments
    @assert_ raw_command in COMMANDS() UnknownCommand(raw_command)

    command::Command = Command(raw_command)
    settings::Settings = set_up(Settings, command)
    arguments::Dict{String, Any} = parse_args(raw_arguments, settings)
    merge!(command.arguments, arguments)
    return command
end

function set_up(::Type{Settings}, command::Command)::Settings
    settings::Settings = compile(Settings, command)
    settings.prog = name(command)
    settings.preformatted_description = true
    settings.description = description(command)
    return settings
end

function usage(c::Command)::String
    return usage(compile(Settings, c))
end

function usage(::Cmd"__main__")::String
    return """
    Usage: $(PROGRAM_FILE) $(join(COMMANDS(), '|')) [-h|--help] ...")

    $(description(cmd"__main__"))
    """
end

end # module
