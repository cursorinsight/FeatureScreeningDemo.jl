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

# Measurement
using FeatureScreeningDemo.Utilities: @with_getters

# Measurement Base API
import Base.Broadcast: broadcastable
import Base: show

# Measurement File API
import FeatureScreening.Utilities: save, load
using FeatureScreening.Utilities: id
using FeatureScreeningDemo.Utilities: print_json, parse_json
using OrderedCollections: OrderedDict

# Benchmark
using FeatureScreeningDemo.Utilities: @with_getters
using UUIDs: UUID
using Dates: DateTime, format
using ProgressMeter: @showprogress

# Benchmark Base API
import Base.Broadcast: broadcastable
using Base.Iterators: product

# Benchmark File API
import FeatureScreening.Utilities: save, load, id, created_at
using Base.Iterators: product
using Dates: now
using FeatureScreening.Utilities: FILENAME_DATETIME_FORMAT
using FeatureScreeningDemo.Utilities: print_json, parse_json
using OrderedCollections: OrderedDict

###=============================================================================
### Implementation
###=============================================================================

###-----------------------------------------------------------------------------
### Measurement
###-----------------------------------------------------------------------------

# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/20
@with_getters struct Measurement
    config
    metrics
end

# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/19
# This is sort of a constructor for `Measurement`
function measure(f::Function, inputs::Tuple; config)
    metrics = f(inputs...; config)
    return Measurement(config, metrics)
end

function metric(measurement::Measurement, key::Symbol)
    return metrics(measurement)[key]
end

##------------------------------------------------------------------------------
## Base API
##------------------------------------------------------------------------------

function broadcastable(measurement::Measurement)::Ref
    return Ref(measurement)
end

# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/21
function show(io::IO, measurement::Measurement)::Nothing
    print(io, "M$(metrics(measurement))")
    return nothing
end

##------------------------------------------------------------------------------
## File API
##------------------------------------------------------------------------------
# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/22

function save(measurement::Measurement;
              directory::AbstractString = "."
             )::Nothing
    filename::String = "$(id(config(measurement))).json"
    path::String = joinpath(directory, filename)
    print_json(path, (config = config(measurement),
                      metrics = metrics(measurement)))
    return nothing
end

function load(::Type{Measurement}, path::AbstractString)::Measurement
    raw::Dict{Symbol, Any} =
        parse_json(path; dicttype = OrderedDict{Symbol, Any})
    config = raw[:config] |> NamedTuple
    metrics = raw[:metrics] |> NamedTuple
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

function Benchmark(f, inputs, config, measurements, description)
    return Benchmark(f, inputs, config, measurements, description, now())
end

function benchmark(f::Function,
                   inputs::Tuple;
                   config,
                   description::String = "",
                   persist::String = ""
                  )::Benchmark
    to_be_persisted::Bool = !isempty(persist)

    configs = product(config)
    benchmark::Benchmark =
        let measurements = Array{Measurement}(undef, size(configs))
            Benchmark(f, inputs, config, measurements, description)
        end

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

function id(benchmark::Benchmark)::UUID
    return benchmark_id(inputs(benchmark), config(benchmark))
end

function benchmark_id(inputs, config)::UUID
    inputs_hash::UInt64 =
        reduce((h, i) -> hash(i, h), inputs; init = UInt64(0))
    config_hash::UInt64 = hash(config)
    return UUID(inputs_hash, config_hash)
end

function missing_f end

###-----------------------------------------------------------------------------
### Base API
###-----------------------------------------------------------------------------

function broadcastable(benchmark::Benchmark)::Ref
    return Ref(benchmark)
end

###-----------------------------------------------------------------------------
### File API
###-----------------------------------------------------------------------------
# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/22

function load(::Type{Benchmark}, path::AbstractString)::Benchmark
    info::NamedTuple =
        parse_json("$path/info.json"; dicttype = OrderedDict{Symbol, Any}) |>
        d -> (description = d[:description], config = NamedTuple(d[:config]))

    measurements::Array{Measurement} = map(product(info[:config])) do config
        return load(Measurement, "$path/measurements/$(id(config)).json")
    end
    return Benchmark(missing_f,
                     (),
                     info[:config],
                     measurements,
                     info[:description])
end

function save(benchmark::Benchmark; directory::AbstractString = ".")::Nothing
    path::String = joinpath(directory, filename(benchmark))
    mkpath(path)
    mkpath("$path/measurements")
    print_json("$path/info.json",
               (description = description(benchmark),
                config = config(benchmark)))

    return nothing
end

function filename(benchmark::Benchmark)::String
    time::String = format(created_at(benchmark), FILENAME_DATETIME_FORMAT)
    return "benchmark.$(id(benchmark)).$(time)"
end

function path(obj; directory = "")::String
    return joinpath(directory, filename(obj))
end

end # module
