###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

###=============================================================================
### Imports
###=============================================================================

using Test

using FeatureScreeningDemo.Utilities: upper_hull, @with_getters
using InteractiveUtils: methodswith

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
            @test_throws UndefVarError __x(t)
            @test_throws UndefVarError x(t)
        end

        @test length(methods(a)) == 1

        @with_getters struct MyOtherType
            a
        end

        @test MyOtherType isa Type
        @test length(methods(a)) == 2

        let t = MyOtherType('b')
            @test t isa MyOtherType
            @test a(t) == 'b'
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

end
