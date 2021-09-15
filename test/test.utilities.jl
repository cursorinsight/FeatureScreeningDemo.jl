###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

###=============================================================================
### Imports
###=============================================================================

using FeatureScreeningDemo.Utilities:
    upper_hull,
    @with_getters,
    @getter,
    @path_str,
    split

using Base: @kwdef

# TODO
using FeatureScreeningDemo.Utilities: FeatureSet, labels

###=============================================================================
### Testset
###=============================================================================

@testset "Utilities" begin

    let points = [(1, 1), (2, 2), (3, 3)]
        @test [[1, 1], [3, 3]] == upper_hull(points)
    end

    let
        @with_getters struct MyType
            a
            b::Int
            c::Vector{<: Real}

            __x::String
        end

        @test MyType isa Type
        @test a isa Function
        @test b isa Function
        @test c isa Function
        @test_throws UndefVarError x
        @test_throws UndefVarError __x

        let t = MyType('a', 1, [2.0], "secret")
            @test t isa MyType
            @test a(t) == 'a'
            @test b(t) == 1
            @test c(t) == [2.0]
            @test_throws UndefVarError x(t)
            @test_throws UndefVarError __x(t)
        end

        @test length(methods(a)) == 1

        @with_getters struct MyOtherType
            a
        end

        @test MyOtherType isa Type
        @test length(methods(a)) == 2
        @test length(methods(b)) == 1
        @test length(methods(c)) == 1

        let t = MyOtherType('b')
            @test t isa MyOtherType
            @test a(t) == 'b'
            @test_throws MethodError b(t)
            @test_throws MethodError c(t)
            @test_throws UndefVarError x(t)
            @test_throws UndefVarError __x(t)
        end
    end

    try
        # TODO this is how you can catch exception from macro
        eval(:(@with_getters struct X{T} end))
    catch exception
        # TODO refactor if previous `eval` was removed
        @test exception isa LoadError
        @test exception.error isa AssertionError
    end

    let
        struct A
            x
        end

        @test_throws UndefVarError x

        @getter x(::A)

        @test x isa Function
        @test x(A(true))
    end

    @test path"a" == "a"
    @test path"a/b" == "a/b"
    @test path"a//b" == "a/b"
    @test path"a///b" == "a/b"
    @test path"" == "." # this is maybe not the most intuitive

    let x = "c"
        @test path"a/b/$x" == "a/b/c"
        @test path"a/b/$(1 + 1)" == "a/b/2"
    end

    let feature_set = rand(FeatureSet, 9600, 10; label_count = 600)
        result = split(feature_set; size = 0.6)
        @test result isa Tuple{<: FeatureSet, <: FeatureSet}
        @test labels(feature_set) == [fill.(1:600, 16)...;]
        @test labels(result[1]) == [fill.(1:600, 9)...;]
        @test labels(result[2]) == [fill.(1:600, 7)...;]
    end

end
