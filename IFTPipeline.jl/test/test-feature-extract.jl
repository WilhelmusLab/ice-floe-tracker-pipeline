using Images
using IFTPipeline: load_labeled_img, save_labeled_img

function test_save_load(image::AbstractArray{T} where T <: Union{UInt8, UInt16, UInt32, UInt64}; extension::AbstractString=".tiff")
    
    filename = tempname() * extension
    
    saved_image = save_labeled_img(image, filename)
    loaded_image = load_labeled_img(saved_image)
    
    @test isequal(image, loaded_image)
end


function test_cast_uncast(image::AbstractArray{T} where T <: Union{UInt8, UInt16, UInt32, UInt64})
    
    casted_image = convert_gray_from_uint(image)
    uncasted_image = convert_uint_from_gray(casted_image)
    
    @test isequal(image, uncasted_image)
    @test isequal(eltype(image), eltype(uncasted_image))
end


@testset "feature-extraction.jl" begin
    image_size = (8, 8)
    
    # Can cast and uncast all sizes of integer
    _test_cast_uncast = test_cast_uncast(rand(t, image_size))
    _test_cast_uncast(UInt8)
    _test_cast_uncast(UInt16)
    _test_cast_uncast(UInt32)
    _test_cast_uncast(UInt64)

    # Can load all sizes of fixed point integer:
    _test_save_load(t) = test_save_load(rand(t, image_size))
    _test_save_load(UInt8)
    _test_save_load(UInt16)
    _test_save_load(UInt32)
    _test_save_load(UInt64)
end