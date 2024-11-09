using Images
using IFTPipeline: load_labeled_img, save_labeled_img

function test_save_load(image::AbstractArray{T} where T <: Union{Gray, Bool}; extension::AbstractString=".tiff")
    
    filename = tempname() * extension
    @info "filename: $filename"
    
    # @info "original: $image"
    
    # @info "saving and loading the image"
    saved_image = save_labeled_img(image, filename)
    loaded_image = load_labeled_img(saved_image)
    
    # @info "loaded: $loaded_image"
    @test isequal(image, loaded_image)
end


@testset "feature-extraction.jl" begin
    # test_save_load(BitArray([1 0; 0 1]))
    
    image_size = (128, 128)
    test_save_load(bitrand(image_size))

    # Can load all sizes of integer:
    test_save_load(rand(Gray{N0f8}, image_size))
    test_save_load(rand(Gray{N0f16}, image_size))
    test_save_load(rand(Gray{N0f32}, image_size))
    test_save_load(rand(Gray{N0f64}, image_size))
end