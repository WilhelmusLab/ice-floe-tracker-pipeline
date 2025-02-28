using Dates

@testset "tracker" begin
    @testset "normal case" begin
        data_dir = joinpath(@__DIR__, "test_inputs/tracker-compressed")
        temp_dir = mkpath(joinpath(@__DIR__, "__temp__/tracker-compressed"))
        results_csv = joinpath(temp_dir, "tracked.csv")

        results = IFTPipeline.track_single(;
            imgs=[
                joinpath(data_dir, "labeled-0.tiff"),
                joinpath(data_dir, "labeled-1.tiff"),
                joinpath(data_dir, "labeled-2.tiff"),
                joinpath(data_dir, "labeled-3.tiff"),
                joinpath(data_dir, "labeled-4.tiff"),
                joinpath(data_dir, "labeled-5.tiff"),
            ],
            props=[
                joinpath(data_dir, "labeled-0.csv"),
                joinpath(data_dir, "labeled-1.csv"),
                joinpath(data_dir, "labeled-2.csv"),
                joinpath(data_dir, "labeled-3.csv"),
                joinpath(data_dir, "labeled-4.csv"),
                joinpath(data_dir, "labeled-5.csv"),
            ],
            passtimes=[
                Dates.DateTime("2000-01-01T00:00:00"),
                Dates.DateTime("2000-01-02T00:00:00"),
                Dates.DateTime("2000-01-03T00:00:00"),
                Dates.DateTime("2000-01-04T00:00:00"),
                Dates.DateTime("2000-01-05T00:00:00"),
                Dates.DateTime("2000-01-06T00:00:00"),
            ],
            latlon=joinpath(data_dir, "labeled-0.tiff"),
            output=results_csv,
            # Optional arguments
            Sminimumarea=0.0,
        )

        @test nrow(results) == 6 * 8 # n observations of m tracked floes
        @test maximum(results.ID) == 8
    end
end
