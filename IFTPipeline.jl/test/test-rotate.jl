using Dates
using LinearAlgebra: dot, det, norm
using IFTPipeline: get_rotation_single, get_rotation_shape_difference

@testset "rotation" begin
    data_dir = joinpath(@__DIR__, "test_inputs", "rotation")
    temp_dir = mkpath(joinpath(@__DIR__, "__temp__", "rotation-single"))
    @testset "normal case" begin
        results = get_rotation_single(;
            input=joinpath(data_dir, "floes.tracked.normal.csv"),
            output=joinpath(temp_dir, "floes.tracked.normal.rotation.csv"),
        )
        @test nrow(results) == 24
    end

    @testset "short case" begin
        results = get_rotation_single(;
            input=joinpath(data_dir, "floes.tracked.short.csv"),
            output=joinpath(temp_dir, "floes.tracked.short.rotation.csv"),
        )
        @test nrow(results) == 2
    end
end