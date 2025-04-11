using IFTPipeline: measure_rotation

@testset "rotation" begin
    data_dir = joinpath(@__DIR__, "test_inputs", "rotation")
    temp_dir = mkpath(joinpath(@__DIR__, "__temp__", "rotation"))

    @testset "normal case" begin
        results = measure_rotation(;
            input=joinpath(data_dir, "floes.tracked.normal.csv"),
            output=joinpath(temp_dir, "floes.tracked.normal.rotation.csv"),
        )
        @test nrow(results) == 24
    end

    @testset "short case" begin
        results = measure_rotation(;
            input=joinpath(data_dir, "floes.tracked.short.csv"),
            output=joinpath(temp_dir, "floes.tracked.short.rotation.csv"),
        )
        @test nrow(results) == 2
    end

    @testset "synthetic case" begin
        results = measure_rotation(;
            input=joinpath(data_dir, "floes.tracked.synthetic.csv"),
            output=joinpath(temp_dir, "floes.tracked.synthetic.rotation.csv"),
        )
        @test nrow(results) == 6
        @test results[1, :theta_deg] == 0
        @test results[2, :theta_deg] == 0
        @test 43 < results[6, :theta_deg] < 47  # should be 45º (clockwise)
    end
end