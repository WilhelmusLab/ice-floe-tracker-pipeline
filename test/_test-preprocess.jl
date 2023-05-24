@testset "preprocess" begin
    @testset "core function" begin
        println("-------------------------------------------------")
        println("-------------  preprocess core ------------------")

        # Uses real test data, no land

        # Simulate the land
        lm = BitMatrix(collect(ones(Bool, ice_floe_test_region)))
        landmask_imgs = (dilated=lm, non_dilated=lm)

        truecolor_img = loadimg(; dir=".", fname=truecolor_test_image_file)[ice_floe_test_region...]
        reflectance_img = loadimg(; dir=".", fname=reflectance_test_image_file)[ice_floe_test_region...]

        segmented_floes = IFTPipeline.preprocess(
            truecolor_img, reflectance_img, landmask_imgs
        )

        segmented_floes_expected = load("$(test_data_dir)/matlab_BW7.png") .> 0.499

        @test test_similarity(
            segmented_floes, segmented_floes_expected[ice_floe_test_region...], 0.056
        )
    end

    @testset "command line" begin
        println("-------------------------------------------------")
        println("-------------preprocess CLI --------------------")
        # Uses toy test data
        imgsdir = joinpath(test_data_dir, "input_pipeline")

        preprocess(;
            truedir=imgsdir, refdir=imgsdir, lmdir=imgsdir, passtimesdir=imgsdir, output=imgsdir
        )

        segfloes_outfile = joinpath(imgsdir, "segmented_floes.jls")
        timedeltas_outfile = joinpath(imgsdir, "timedeltas.jls")
        @test isfile(segfloes_outfile)
        @test isfile(timedeltas_outfile)
        rm.([segfloes_outfile, timedeltas_outfile])
    end
end
