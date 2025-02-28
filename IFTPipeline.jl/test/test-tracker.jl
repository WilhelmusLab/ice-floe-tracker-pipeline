using Dates

@testset "tracker" begin
    data_dir = joinpath(@__DIR__, "test_inputs/tracker-single")
    temp_dir = mkpath(joinpath(@__DIR__, "__temp__/tracker-single"))

    passtimes = [
        Dates.DateTime("2000-01-01T00:00:00"),
        Dates.DateTime("2000-01-02T00:00:00"),
        Dates.DateTime("2000-01-03T00:00:00"),
        Dates.DateTime("2000-01-04T00:00:00"),
        Dates.DateTime("2000-01-05T00:00:00"),
        Dates.DateTime("2000-01-06T00:00:00"),
    ]

    @testset "normal case" begin
        results = IFTPipeline.track_single(;
            imgs=[
                joinpath(data_dir, "images/labeled-0.tiff"),
                joinpath(data_dir, "images/labeled-1.tiff"),
                joinpath(data_dir, "images/labeled-2.tiff"),
                joinpath(data_dir, "images/labeled-3.tiff"),
                joinpath(data_dir, "images/labeled-4.tiff"),
                joinpath(data_dir, "images/labeled-5.tiff"),
            ],
            props=[
                joinpath(data_dir, "floes-gte-350-px/labeled-0.csv"),
                joinpath(data_dir, "floes-gte-350-px/labeled-1.csv"),
                joinpath(data_dir, "floes-gte-350-px/labeled-2.csv"),
                joinpath(data_dir, "floes-gte-350-px/labeled-3.csv"),
                joinpath(data_dir, "floes-gte-350-px/labeled-4.csv"),
                joinpath(data_dir, "floes-gte-350-px/labeled-5.csv"),
            ],
            passtimes=passtimes,
            latlon=joinpath(data_dir, "labeled-0.tiff"),
            output=joinpath(temp_dir, "tracked-floes-gte-350-px.csv"),

            # Optional arguments
            Sminimumarea=0.0,
        )

        @test nrow(results) == 6 * 8 # n observations of m tracked floes
        @test maximum(results.ID) == 8
    end

    @testset "no crash with medium floes" begin
        results = IFTPipeline.track_single(;
            imgs=[
                joinpath(data_dir, "images/labeled-0.tiff"),
                joinpath(data_dir, "images/labeled-1.tiff"),
                joinpath(data_dir, "images/labeled-2.tiff"),
                joinpath(data_dir, "images/labeled-3.tiff"),
                joinpath(data_dir, "images/labeled-4.tiff"),
                joinpath(data_dir, "images/labeled-5.tiff"),
            ],
            props=[
                joinpath(data_dir, "floes-gte-200-px/labeled-0.csv"),
                joinpath(data_dir, "floes-gte-200-px/labeled-1.csv"),
                joinpath(data_dir, "floes-gte-200-px/labeled-2.csv"),
                joinpath(data_dir, "floes-gte-200-px/labeled-3.csv"),
                joinpath(data_dir, "floes-gte-200-px/labeled-4.csv"),
                joinpath(data_dir, "floes-gte-200-px/labeled-5.csv"),
            ],
            passtimes=passtimes,
            latlon=joinpath(data_dir, "labeled-0.tiff"),
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
            imgs=[
                joinpath(data_dir, "images/labeled-0.tiff"),
                joinpath(data_dir, "images/labeled-1.tiff"),
                joinpath(data_dir, "images/labeled-2.tiff"),
                joinpath(data_dir, "images/labeled-3.tiff"),
                joinpath(data_dir, "images/labeled-4.tiff"),
                joinpath(data_dir, "images/labeled-5.tiff"),
            ],
            props=[
                joinpath(data_dir, "floes-gte-50-px/labeled-0.csv"),
                joinpath(data_dir, "floes-gte-50-px/labeled-1.csv"),
                joinpath(data_dir, "floes-gte-50-px/labeled-2.csv"),
                joinpath(data_dir, "floes-gte-50-px/labeled-3.csv"),
                joinpath(data_dir, "floes-gte-50-px/labeled-4.csv"),
                joinpath(data_dir, "floes-gte-50-px/labeled-5.csv"),
            ],
            passtimes=passtimes,
            latlon=joinpath(data_dir, "labeled-0.tiff"),
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
end
