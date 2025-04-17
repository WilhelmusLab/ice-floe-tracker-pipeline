using Dates
using TimeZones

@testset "tracker" begin
    function run_tracker(;
        props_directory_name="floes-gte-350-px",
        data_dir=joinpath(@__DIR__, "test_inputs", "tracker-single"),
        temp_dir=mkpath(joinpath(@__DIR__, "__temp__", "tracker-single")),
        passtimes=[
            TimeZones.ZonedDateTime("2000-01-01T00:00:00Z") + Dates.Day(i) for i in 1:6
        ],
    )
        imgs = [joinpath(data_dir, "images", "labeled-$(i).tiff") for i in 0:5]
        latlon = imgs[1]
        props = [joinpath(data_dir, props_directory_name, "labeled-$(i).csv") for i in 0:5]
        output = joinpath(temp_dir, "tracked-$(props_directory_name).csv")

        return IFTPipeline.track_single(;
            imgs,
            props,
            passtimes,
            latlon,
            output,

            # Optional arguments
            Sminimumarea=0.0,
        )
    end

    @testset "normal case" begin
        results = run_tracker(; props_directory_name="floes-gte-350-px")
        @test nrow(results) == 6 * 8 # n observations of m tracked floes
        @test maximum(results.ID) == 8
    end

    @testset "no crash with medium floes" begin
        results = run_tracker(; props_directory_name="floes-gte-200-px")

        # Empirical testing – there should be at least 18 floes tracked
        @test maximum(results.ID) >= 18
        @test nrow(results) >= 18 * 6

        # Maximum number of valid floes is 22
        @test maximum(results.ID) <= 22
        @test nrow(results) <= 22 * 6
    end

    @testset "including small floes" begin
        results = run_tracker(; props_directory_name="floes-gte-50-px")

        # Empirical testing – there should be at least 18 floes tracked
        @test maximum(results.ID) >= 18
        @test nrow(results) >= 18 * 6

        # Maximum number of valid floes is 40
        @test maximum(results.ID) <= 40
        @test nrow(results) <= 40 * 6
    end

    @testset "drop some detections" begin
        results = run_tracker(; props_directory_name="floes-gte-350-px-some-floes-missing")

        # There should be 8 floes tracked in total
        @test maximum(results.ID) == 8

        # ... but only 24 matched rows
        @test nrow(results) == 24
    end

    @testset "some empty fields" begin
        results = run_tracker(; props_directory_name="floes-gte-350-px-some-days-missing")

        # There should be 8 floes tracked in total
        @test maximum(results.ID) == 8

        # ... but only 16 matched rows
        @test nrow(results) == 16
    end

    @testset "some orphan floes" begin
        results = run_tracker(; props_directory_name="floes-gte-350-px-orphan-floes")

        # There should be 6 floes tracked in total
        @test maximum(results.ID) == 6
        @test nrow(results) == 6 * 6

        # And the largest floe should be < 2500 pixels in area, 
        # because the two floes larger than that are only in the first field
        @test maximum(results.area) < 2500
    end
end
