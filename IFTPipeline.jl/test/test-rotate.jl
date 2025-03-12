using Dates

@testset "tracker" begin
    data_dir = joinpath(@__DIR__, "test_inputs", "rotation")
    temp_dir = mkpath(joinpath(@__DIR__, "__temp__", "rotation-single"))
    @testset "normal case" begin
        results = IFTPipeline.get_rotation_single(;
            input=joinpath(data_dir, "floes.tracked.satellite.csv"),
            output=joinpath(temp_dir, "floes.tracked.satellite.rotation.csv"),
        )
        @test nrow(results) == 24
    end

    @testset "short case" begin
        results = IFTPipeline.get_rotation_single(;
            input=joinpath(data_dir, "floes.tracked.short.csv"),
            output=joinpath(temp_dir, "floes.tracked.short.rotation.csv"),
        )
        @test nrow(results) == 2
    end

    @testset "synthetic case" begin
        results = IFTPipeline.get_rotation_single(;
            input=joinpath(data_dir, "floes.tracked.synthetic.csv"),
            output=joinpath(temp_dir, "floes.tracked.synthetic.rotation.csv"),
        )
        @test nrow(results) == 6
        @test results[1, :theta_deg] == 0
        @test results[2, :theta_deg] == 0
        @test 35 < results[6, :theta_deg] < 50  # should be 45º
    end
end
