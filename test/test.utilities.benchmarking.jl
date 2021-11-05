###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

###=============================================================================
### Imports
###=============================================================================

using FeatureScreeningDemo.Utilities.Benchmarking:
    benchmark,
    Benchmark,
    measurements,
    Measurement,
    metric

using FeatureScreeningDemo.Utilities.Benchmarking: save, load

###=============================================================================
### Testset
###=============================================================================

@testset "Benchmarking" begin
    function my_sleep(t::Real; config)
        value::Real = config[:multiplier] * 2t
        return (; value, elapsed = @elapsed sleep(value))
    end

    dir::String = tempname()
    t::Real = 0.01
    multiplier = 1:10
    result = benchmark(my_sleep,
                       (t,);
                       config = (; multiplier),
                       persist = dir)

    @test result isa Benchmark
    ms = measurements(result)
    @test ms isa Vector{Measurement}

    @test all(t .* multiplier .< metric.(ms, :value) .<= metric.(ms, :elapsed))

    @test isdir(dir)
    @test length(readdir(dir)) == 1
    benchmark_dir::String = path"$dir/$(readdir(dir)[1])"
    @test isdir(benchmark_dir)
    @test readdir(benchmark_dir) == ["info.json", "measurements"]
    measurement_dir::String = path"$benchmark_dir/measurements"
    measurement_files::Vector{String} = readdir(measurement_dir)
    @test length(measurement_files) == 10

    let dir2::String = tempname()
        @test !isdir(dir2)
        @test save(result; directory = dir2) isa Nothing
        @test isdir(dir2)
        @test length(readdir(dir2)) == 1
        benchmark_dir2::String = path"$dir2/$(readdir(dir2)[1])"
        @test isdir(benchmark_dir2)
        @test readdir(benchmark_dir2) == ["info.json", "measurements"]
        measurement_dir2::String = path"$benchmark_dir2/measurements"
        measurement_files2::Vector{String} = readdir(measurement_dir2)
        @test_broken length(measurement_files2) == 10
        @test_broken measurement_files == measurement_files2
    end

    let benchmark = load(Benchmark, benchmark_dir)
        @test benchmark isa Benchmark
        @test_broken benchmark.__f == my_sleep
        @test_broken benchmark.inputs == (0.01,)
        @test all(benchmark.measurements .== ms)
        @test benchmark.description == ""
    end
end
