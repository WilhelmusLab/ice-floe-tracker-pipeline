using Dates

@testset "tracker" begin
    data_dir = joinpath(@__DIR__, "test_inputs/tracker-single")
    temp_dir = mkpath(joinpath(@__DIR__, "__temp__/tracker-single"))

    imgs = [joinpath(data_dir, "images/labeled-$(i).tiff") for i in range(0, 5)]
    passtimes = [Dates.DateTime("2000-01-0$(i)T00:00:00") for i in range(1, 6)]
    latlon = imgs[1]

    @testset "normal case" begin
        results = IFTPipeline.track_single(;
            imgs=imgs,
            props=[
                joinpath(data_dir, "floes-gte-350-px/labeled-$(i).csv") for i in range(0, 5)
            ],
            passtimes=passtimes,
            latlon=latlon,
            output=joinpath(temp_dir, "tracked-floes-gte-350-px.csv"),

            # Optional arguments
            Sminimumarea=0.0,
        )

        @test nrow(results) == 6 * 8 # n observations of m tracked floes
        @test maximum(results.ID) == 8
    end

    @testset "no crash with medium floes" begin
        results = IFTPipeline.track_single(;
            imgs=imgs,
            props=[
                joinpath(data_dir, "floes-gte-200-px/labeled-$(i).csv") for i in range(0, 5)
            ],
            passtimes=passtimes,
            latlon=latlon,
            output=joinpath(temp_dir, "tracked-floes-gte-200-px.csv"),

            # Optional arguments
            Sminimumarea=0.0,
        )

        # Empirical testing – there should be at least 18 floes tracked
        @test maximum(results.ID) >= 18
        @test nrow(results) >= 18 * 6

        # Maximum number of valid floes is 22
        @test maximum(results.ID) <= 22
        @test nrow(results) <= 22 * 6
    end

    @testset "including small floes" begin
        results = IFTPipeline.track_single(;
            imgs=imgs,
            props=[
                joinpath(data_dir, "floes-gte-50-px/labeled-$(i).csv") for i in range(0, 5)
            ],
            passtimes=passtimes,
            latlon=latlon,
            output=joinpath(temp_dir, "tracked-floes-gte-50-px.csv"),

            # Optional arguments
            Sminimumarea=0.0,
        )

        # Empirical testing – there should be at least 18 floes tracked
        @test maximum(results.ID) >= 18
        @test nrow(results) >= 18 * 6

        # Maximum number of valid floes is 40
        @test maximum(results.ID) <= 40
        @test nrow(results) <= 40 * 6
    end

    @testset "drop some detections" begin
        results = IFTPipeline.track_single(;
            imgs=imgs,
            props=[
                joinpath(data_dir, "floes-gte-350-px-some-missing/labeled-$(i).csv") for
                i in range(0, 5)
            ],
            passtimes=passtimes,
            latlon=latlon,
            output=joinpath(temp_dir, "tracked-floes-gte-350-px-some-missing.csv"),

            # Optional arguments
            Sminimumarea=0.0,
        )

        # There should be 8 floes tracked in total
        @test maximum(results.ID) == 8

        # ... but only 24 matched rows
        @test nrow(results) == 24
    end
end
