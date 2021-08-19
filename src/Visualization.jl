###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Visualization

###=============================================================================
### Exports
###=============================================================================

export plot, save

###=============================================================================
### Imports
###=============================================================================

import PlotlyJS: plot, scatter
using PlotlyJS: savefig
using FeatureScreening.Types: FeatureSet, labels, features
using FeatureScreeningDemo.Utilities: upper_hull
using FeatureScreeningDemo.Benchmarking: Measurement, metric, config

###=============================================================================
### Implementation
###=============================================================================

function plot(feature_set::FeatureSet{L}) where {L}
    # TODO remove if feature set has information about the labels
    # Collect label indices
    idxs = Dict{L, Vector{Int}}()
    foldl(enumerate(labels(feature_set)); init = idxs) do idxs, (idx, label)
        push!(get!(idxs, label, Int[]), idx)
        return idxs
    end

    # TODO never use Plotly again
    return plot([let x = [fill.(1:size(feature_set, 2), length(idxs))...;],
                     y = reshape(features(feature_set[idxs, :]), :)
                     scatter(x = x, y = y, name = label, mode = "markers")
                 end
                 for (label, idxs) in sort!(collect(idxs); by = first)])
end

# TODO refactor
function scatter(measurements::Array{Measurement};
                 x::Symbol = keys(metrics(measurements[1]))[1], # TODO remove
                 y::Symbol = keys(metrics(measurements[1]))[2], # TODO remove
                 kwargs...)
    x::Vector{<: Real} = metric.(measurements, x) |> vec
    y::Vector{<: Real} = metric.(measurements, y) |> vec
    text::Vector{String} = scatter_text(measurements) |> vec
    return scatter(; x, y, text, kwargs...)
end

# TODO refactor
function plot(measurements::Array{Measurement};
              group_by::Symbol,
              x::Symbol,
              y::Symbol,
              format::String = "",
              hull::Bool = true,
              kwargs...)

    configs::Vector{<: NamedTuple} =
        unique(complement.(config.(measurements), group_by))

    common_config::NamedTuple =
        foldl(intersect, pairs.(configs)) |> NamedTuple

    configs = map(configs) do config
        return filter(pairs(config)) do (key, value)
            return !(key in keys(common_config))
        end |> NamedTuple
    end

    data_series::Vector{<: Vector} =
        [select_data(measurements, config) for config in configs]

    lines::Vector =
        [let name::String = format_name(format, config)
             scatter(data; x, y, name, kwargs...)
         end
         for (data, config) in zip(data_series, configs)]

    if hull
        points::Vector{<: Vector} =
            [metric.(m, [x, y]) for m in vec(measurements)]
        points = upper_hull(points)
        x = first.(points)
        y = last.(points)
        push!(lines, scatter(; x, y, name = "Envelope", line_width = 5))
    end

    return plot(lines)
end

# TODO remove/refactor
function scatter_text(measurements::Array{Measurement, N}
                     )::Array{String, N} where {N}
    return scatter_text.(measurements)
end

# TODO remove/refactor
function scatter_text(measurement::Measurement)::String
    return join(["$k:$v" for (k, v) in pairs(config(measurement))], '\n')
end

# TODO remove/refactor
function complement(nt::NamedTuple, exempt_key::Symbol)
    return NamedTuple(filter(nt -> nt[1] != exempt_key, pairs(nt)))
end

function format_name(fmt::String, config::NamedTuple)
# TODO remove/refactor
    if (fmt == "")
        return join(["$(k):$(config[k])" for k in keys(config)], "_")
    end
    regex = Regex(join((k -> "{$(k)}").(keys(config)), "|"))
    return replace(fmt, regex => s -> config[Symbol(s[2:end-1])])
end

# TODO remove/refactor
function select_data(measurements::Array{Measurement},
                     criteria::NamedTuple
                    )::Array{Measurement}
    return filter(measurements) do m
        return all(m.config[k] == criteria[k] for k in keys(criteria))
    end
end

function save(filename::AbstractString, plot; kwargs...)
    return savefig(plot, filename; kwargs...)
end

end # module
