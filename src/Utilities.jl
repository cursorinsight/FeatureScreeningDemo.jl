###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Utilities

###=============================================================================
### Imports
###=============================================================================

import Base: NamedTuple

using Base.Iterators: filter
import Base.Iterators: product

using LazySets: convex_hull

using Dates: now, format as _format, DateTime, DateFormat

import UUIDs: UUID

using JSON.Writer: print as _print_json
using JSON.Parser: parsefile as _parse_json
using OrderedCollections: OrderedDict

# TODO remove if possible
import FeatureScreening: load

using MacroTools: isstructdef, @capture
using Base: Fix1

using OrderedCollections: OrderedDict
using FeatureScreening.Types: FeatureSet, labels

import Base: split

using Base.Meta: parse
using FeatureScreening.Utilities: FILENAME_DATETIME_FORMAT

###=============================================================================
### API
###=============================================================================

function hitrate(a::AbstractArray, b::AbstractArray)::Float64
    @assert size(a) == size(b)
    return count(a .== b) / length(a)
end

function NamedTuple(keys, values)
    return NamedTuple{Tuple(keys)}(values)
end

# TODO This should/could/might be lazy.
# TODO Because of the iteration over `String` in `product` causes (A) and (B).
# Maybe not necessary.
function product(kvs::NamedTuple)
    # TODO (A)
    to_be_exposed = __to2exposed(kvs)
    ks = first.(to_be_exposed)
    vs = last.(to_be_exposed)
    return map(product(vs...)) do vs::Tuple
        # TODO (B)
        return merge(kvs, NamedTuple(ks, vs))
    end
end

function __to2exposed(kvs::NamedTuple)
    return filter(pairs(kvs)) do (k, v)
        return v isa AbstractVector
    end |> collect
end

# TODO
function upper_hull(points::Vector)::Vector{<: Vector}
    # TODO `convex_hull` works on vector of vectors.
    points = [[coords...] for coords in points]
    hull::Vector{<: Vector} = convex_hull(points)
    (i::Int, j::Int) = (argmin(hull), argmax(hull))
    # TODO this is how it works for us
    return hull[[i:-1:begin; end:-1:j]]
end

function now2(datetime = now(), format = FILENAME_DATETIME_FORMAT)::String
    return _format(datetime, format)
end

function UUID(high::UInt64, low::UInt64)::UUID
    return UUID(UInt128(high) << 64 + UInt128(low))
end

function print_json(path::AbstractString, obj; kwargs...)::Nothing
    open(path, "w") do io
        print_json(io, obj; kwargs...)
    end
    return nothing
end

function print_json(io::IO, obj; indent = 2)::Nothing
    _print_json(io, obj, indent)
    return nothing
end

function parse_json(path::AbstractString;
                    dicttype::Type{T} = Dict{Symbol, Any},
                    kwargs...
                   )::T where {T}
    _parse_json(path; dicttype, kwargs...)
end

# TODO
function load(::Type{NamedTuple}, path::AbstractString)::NamedTuple
    @assert ispath(path)
    kvs = parse_json(path; dicttype = OrderedDict{Symbol, Any})
    return convert_rec(NamedTuple, kvs)
end

function convert_rec(::Type{NamedTuple}, kvs::AbstractDict)::NamedTuple
    return NamedTuple(k => convert_rec(NamedTuple, v) for (k, v) in kvs)
end

function convert_rec(::Type{NamedTuple}, x)
    return x
end

macro with_getters(expr)
    @assert isstructdef(expr)
    @capture expr struct T_ fields__ end
    @assert T isa Symbol "Struct must be non-parametric"

    getter_functions::Vector{Expr} =
        filter(!is_private_field, fields) .|> getter_fun_expr(T)

    return quote
        $expr
        $(getter_functions...)
    end |> esc
end

macro getter(expr)
    @capture(expr, f_(::T_))
    getter::Expr = getter_fun_expr(T, f)
    return :($getter) |> esc
end

function is_private_field(field::Symbol)::Bool
    return occursin(r"^__", String(field))
end

function is_private_field(expr::Expr)::Bool
    return is_private_field(expr.args[1])
end

function getter_fun_expr(T)::Function
    return Fix1(getter_fun_expr, T)
end

function getter_fun_expr(T, expr::Expr)::Expr
    @assert expr.head == :(::)
    return getter_fun_expr(T, expr.args...)
end

function getter_fun_expr(T, field::Symbol, F = :Any)::Expr
    return quote
        function $field(x::$T)::$F
            return x.$field
        end
    end
end

function projectpath(parts::AbstractString...)::String
    return joinpath(@__DIR__, "..", parts...)
end

function group_by(f::Function, itr::AbstractVector{T})::OrderedDict where {T}
    return foldl(itr; init = OrderedDict{Any, Vector{T}}()) do acc, x
        push!(get!(acc, f(x), T[]), x)
        return acc
    end
end

function group_by(itr::AbstractVector)
    return group_by(identity, itr)
end

function split(itr; size::Real = 0.5)::Tuple
    @assert 0 <= size <= 1
    i = floor(Int, length(itr) * size)
    return (itr[begin:i], itr[i+1:end])
end

function split(feature_set::T;
               dim = 1,
               kwargs...
              )::Tuple{T, T} where {T <: FeatureSet}
    # TODO
    @assert dim == 1 "Just row oriented splitting were implemented."

    labels_by_idxs::Vector =
        [idx => label for (idx, label) in enumerate(labels(feature_set))]
    by_labels::OrderedDict = group_by(last, labels_by_idxs)

    idxs::Function = first

    (train_idxs::Vector{Int}, test_idxs::Vector{Int}) =
        foldl(collect(by_labels); init = (Int[], Int[])) do acc, (_, group)
            (train, test) = split(idxs.(group); kwargs...)
            append!(acc[1], train)
            append!(acc[2], test)
            return acc
        end

    return (feature_set[train_idxs, :], feature_set[test_idxs, :])
end

macro path_str(str::String)
    return Expr(:call, :normpath, esc(parse("\"$str\"")))
end

end # module
