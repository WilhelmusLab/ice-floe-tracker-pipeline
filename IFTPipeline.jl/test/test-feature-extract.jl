using Images
using IFTPipeline: load_labeled_img, save_labeled_img

function test_save_load(image::AbstractArray{T} where T <: Union{UInt8, Int8, UInt16, Int16, UInt32, Int32, UInt64, Int64}; extension::AbstractString=".tiff")
    
    filename = tempname() * extension
    
    saved_image = save_labeled_img(image, filename)
    loaded_image = load_labeled_img(saved_image)
    
    @test isequal(image, loaded_image)
end


function test_cast_uncast(image)
    
    casted_image = convert_gray_from_uint(image)
    uncasted_image = convert_uint_from_gray(casted_image)
    
    @test isequal(image, uncasted_image)
    @test isequal(eltype(image), eltype(uncasted_image))
end


@testset "feature-extraction.jl" begin
    image_size = (8, 8)
    
    # Can cast and uncast all sizes of unsigned integer
    test_cast_uncast(rand(UInt8, image_size))
    test_cast_uncast(rand(UInt16, image_size))
    test_cast_uncast(rand(UInt32, image_size))
    test_cast_uncast(rand(UInt64, image_size))

    # ... and signed integer
    test_cast_uncast(rand(Int8, image_size))
    test_cast_uncast(rand(Int16, image_size))
    test_cast_uncast(rand(Int32, image_size))
    test_cast_uncast(rand(Int64, image_size))

    # Can load all sizes of unsigned integer:
    test_save_load(rand(UInt8, image_size))
    test_save_load(rand(UInt16, image_size))
    test_save_load(rand(UInt32, image_size))
    test_save_load(rand(UInt64, image_size))

    # ... and signed integer
    test_save_load(rand(Int8, image_size))
    test_save_load(rand(Int16, image_size))
    test_save_load(rand(Int32, image_size))
    test_save_load(rand(Int64, image_size))
end