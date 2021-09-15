###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Benchmarking

###=============================================================================
### Exports
###=============================================================================

export benchmark, measure, Measurement

###=============================================================================
### Imports
###=============================================================================

using UUIDs: UUID
import Base: show
using ProgressMeter: @showprogress
using Base.Iterators: product
using Dates: DateTime, now, format
using FeatureScreeningDemo.Utilities: print_json, parse_json
using FeatureScreeningDemo.Utilities: @with_getters
using FeatureScreening.Utilities: FILENAME_DATETIME_FORMAT
import FeatureScreening.Utilities: save, load, id, created_at

###=============================================================================
### Implementation
###=============================================================================

###-----------------------------------------------------------------------------
### Measurement
###-----------------------------------------------------------------------------

@with_getters struct Measurement
    config
    metrics
end

function metric(measurement::Measurement, key::Symbol)
    return metrics(measurement)[key]
end

function show(io::IO, measurement::Measurement)::Nothing
    # TODO add config
    print(io, "M$(metrics(measurement))")
    return nothing
end

# TODO this should/could be a macro probably like this:
# `@measure my_cool_metric(42) config = (this = :will, be = "great")`
# This is sort of a constructor for `Measurement`
function measure(f::Function, inputs::Tuple; config)
    metrics = f(inputs...; config)
    # TODO id
    return Measurement(config, metrics)
end

###-----------------------------------------------------------------------------
### File I/O
###-----------------------------------------------------------------------------

function save(measurement::Measurement;
              directory::AbstractString = "."
             )::Nothing
    # TODO remove hash
    filename::String = "$(id(config(measurement))).json"
    path::String = joinpath(directory, filename)
    print_json(path, (config = config(measurement),
                      metrics = metrics(measurement)))
    return nothing
end

# TODO
function load(::Type{Measurement}, path::AbstractString)::Measurement
    raw::Dict{Symbol, Any} = parse_json(path)
    (raw_config_id::String, _ext) = splitext(basename(path))
    config = raw[:config] |> NamedTuple
    metrics = raw[:metrics] |> NamedTuple
    @assert UUID(raw_config_id) == id(config)
    return Measurement(config, metrics)
end

###-----------------------------------------------------------------------------
### Benchmark
###-----------------------------------------------------------------------------

@with_getters struct Benchmark
    __f::Function
    inputs::Tuple
    config
    measurements::Array{<: Measurement}
    description::String
    created_at::DateTime
end

# TODO maybe replace this with `Base.@kwdef`
function Benchmark(f, inputs, config, measurements, description)
    return Benchmark(f, inputs, config, measurements, description, now())
end

# TODO this implementation assumes inputs isn't empty
function id(benchmark::Benchmark)::UUID
    return benchmark_id(inputs(benchmark), config(benchmark))
end

# TODO
function benchmark_id(inputs, config)::UUID
    inputs_hash::UInt64 =
        reduce((h, i) -> hash(i, h), inputs; init = UInt64(0))
    config_hash::UInt64 = hash(config)
    return UUID(inputs_hash, config_hash)
end

isundef(::UndefInitializer) = true
isundef(::Any) = false

function save(benchmark::Benchmark; directory::AbstractString = ".")::Nothing
    path::String = joinpath(directory, filename(benchmark))
    mkpath(path)
    mkpath("$path/measurements")
    print_json("$path/info.json",
               (description = description(benchmark),
                config = config(benchmark)))
    # TODO save measurements

    return nothing
end

function filename(benchmark::Benchmark)::String
    time::String = format(created_at(benchmark), FILENAME_DATETIME_FORMAT)
    return "benchmark.$(id(benchmark)).$(time)"
end

function path(obj; directory = "")::String
    return joinpath(directory, filename(obj))
end

# TODO maybe find a better way to persist the executed measurements or whatever
function benchmark(f::Function,
                   inputs::Tuple;
                   config,
                   description::String = "",
                   persist::String = ""
                  )::Benchmark
    to_be_persisted::Bool = !isempty(persist)

    configs = product(config)
    _measurements = Array{Measurement}(undef, size(configs))
    benchmark::Benchmark =
        Benchmark(f, inputs, config, _measurements, description)

    if to_be_persisted
        save(benchmark; directory = persist)
    end

    @showprogress "Benchmark $(description)" for (i, config) in pairs(configs)
        measurements(benchmark)[i] = measure(f, inputs; config)
        if to_be_persisted
            directory = "$(path(benchmark; directory = persist))/measurements"
            save(measurements(benchmark)[i]; directory)
        end
    end

    return benchmark
end

end # module
