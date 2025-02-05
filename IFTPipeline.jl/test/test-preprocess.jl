@testset "preprocess" begin
    @testset "cloudy image with no ice" begin
        println("-------------------------------------------------")
        println("--------- cloudy image with no ice --------------")
        input_dir = joinpath(test_data_dir, "preprocess/cloudy")
        IFTPipeline.preprocess_single(;
            truecolor=joinpath(input_dir, "truecolor.tiff"),
            falsecolor=joinpath(input_dir, "falsecolor.tiff"),
            landmask=joinpath(input_dir, "landmask.non-dilated.tiff"),
            landmask_dilated=joinpath(input_dir, "landmask.dilated.tiff"),
            output=(output_path = joinpath(mktempdir(), "output.tiff")),
        )
    end
end
