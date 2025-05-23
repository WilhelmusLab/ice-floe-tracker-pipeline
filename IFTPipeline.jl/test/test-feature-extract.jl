using Images
using IFTPipeline: load_labeled_img, save_labeled_img

function test_save_load(image; extension=".tiff")
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
    _test_cast_uncast(t) = test_cast_uncast(rand(t, image_size))
    _test_cast_uncast(UInt8)
    _test_cast_uncast(UInt16)
    _test_cast_uncast(UInt32)
    _test_cast_uncast(UInt64)

    # ... and signed integer
    _test_cast_uncast(Int8)
    _test_cast_uncast(Int16)
    _test_cast_uncast(Int32)
    _test_cast_uncast(Int64)

    # Can save and load all sizes of unsigned integer:
    _test_save_load(t) = test_save_load(rand(t, image_size))
    _test_save_load(UInt8)
    _test_save_load(UInt16)
    _test_save_load(UInt32)
    _test_save_load(UInt64)

    # ... and signed integer
    _test_save_load(Int8)
    _test_save_load(Int16)
    _test_save_load(Int32)
    _test_save_load(Int64)
end
