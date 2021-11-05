###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module Utilities

###=============================================================================
### Imports
###=============================================================================

# File I/O
import FeatureScreening.Utilities: load
using OrderedCollections: OrderedDict

# JSON related
using JSON.Writer: print as __print_json
using JSON.Parser: parsefile as __parse_json

# Getter generator
using Base.Iterators: filter
using MacroTools: isstructdef, @capture

# `Base` extensions
import Base: NamedTuple
import Base.Iterators: product
import Base: split

# Rest
using Dates: now, format as __format
using FeatureScreening.Utilities: FILENAME_DATETIME_FORMAT
using LazySets: convex_hull
import UUIDs: UUID
using OrderedCollections: OrderedDict
import Base: split
using FeatureScreening.Types: FeatureSet, labels
using Base.Meta: parse as __parse
using Base: Fix1

###=============================================================================
### API
###=============================================================================

###-----------------------------------------------------------------------------
### File I/O
###-----------------------------------------------------------------------------

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

###-----------------------------------------------------------------------------
### Path helpers
###-----------------------------------------------------------------------------

function projectpath(parts::AbstractString...)::String
    return joinpath(@__DIR__, "..", parts...)
end

macro path_str(str::String)
    return :(normpath($(esc(__parse("\"$str\"")))))
end

macro pwd_str(str::String)
    return :(joinpath(pwd(), normpath($(esc(__parse("\"$str\""))))))
end

###-----------------------------------------------------------------------------
### JSON related
###-----------------------------------------------------------------------------

function print_json(path::AbstractString, obj; kwargs...)::Nothing
    open(path, "w") do io
        print_json(io, obj; kwargs...)
    end
    return nothing
end

function print_json(io::IO, obj; indent = 2)::Nothing
    __print_json(io, obj, indent)
    return nothing
end

function parse_json(path::AbstractString;
                    dicttype::Type{T} = Dict{Symbol, Any},
                    kwargs...
                   )::T where {T}
    __parse_json(path; dicttype, kwargs...)
end

###-----------------------------------------------------------------------------
### Getter generator
###-----------------------------------------------------------------------------

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

###-----------------------------------------------------------------------------
### `Base` extensions
###-----------------------------------------------------------------------------

function NamedTuple(keys, values)
    return NamedTuple{Tuple(keys)}(values)
end

# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/18
# Because of the iteration over `String` in `product` causes [A] and [B].
function product(kvs::NamedTuple)
    # [A]
    to_be_exposed = filter(pairs(kvs)) do (k, v)
        return v isa AbstractVector
    end |> collect
    ks = first.(to_be_exposed)
    vs = last.(to_be_exposed)
    return map(product(vs...)) do vs::Tuple
        # [B]
        return merge(kvs, NamedTuple(ks, vs))
    end
end

function split(itr; size::Real = 0.5)::Tuple
    @assert 0 <= size <= 1
    i = floor(Int, length(itr) * size)
    return (itr[begin:i], itr[i+1:end])
end

###-----------------------------------------------------------------------------
### Rest
###-----------------------------------------------------------------------------

function hitrate(a::AbstractArray, b::AbstractArray)::Float64
    @assert size(a) == size(b)
    return count(a .== b) / length(a)
end

function now2(datetime = now(), format = FILENAME_DATETIME_FORMAT)::String
    return __format(datetime, format)
end

"""
    upper_hull(points::Vector)::Vector{<: Vector}

This is not a general purpose upper hull function. Just wrapping a weird
implementation to integrate into a weirder one.
"""
function upper_hull(points::Vector)::Vector{<: Vector}
    points = [[coords...] for coords in points]
    hull::Vector{<: Vector} = convex_hull(points)
    (i::Int, j::Int) = (argmin(hull), argmax(hull))
    return hull[[i:-1:begin; end:-1:j]]
end

function UUID(high::UInt64, low::UInt64)::UUID
    return UUID(UInt128(high) << 64 + UInt128(low))
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

# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/17
function split(feature_set::T;
               dim = 1,
               kwargs...
              )::Tuple{T, T} where {T <: FeatureSet}
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

function parse(::Type{T})::Function where {T}
    return Fix1(parse, T)
end

# TODO
include("utilities/Benchmarking.jl")
include("utilities/CommandLine.jl")

end # module
