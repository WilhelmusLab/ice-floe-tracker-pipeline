function check_landmask_path(lmpath::String)::Nothing
    name = basename(lmpath)
    input = dirname(lmpath)
    !isfile(lmpath) && error(
        "`$(name)` not found in $input. Please ensure a coastline image file named `$name` exists in $input.",
    )
    return nothing
end

"""
    cache_vector(type::Type, numel::Int64, size::Tuple{Int64, Int64})::Vector{type}

Build a vector of types `type` with `numel` elements of size `size`.

Example

```jldoctest
julia> cache_vector(Matrix{Float64}, 3, (2, 2))
3-element Vector{Matrix{Float64}}:
 [0.0 6.9525705991269e-310; 6.9525705991269e-310 0.0]
 [0.0 6.9525705991269e-310; 6.9525705991269e-310 0.0]
 [0.0 6.95257028858726e-310; 6.95257029000147e-310 0.0]
```
"""
function cache_vector(type::Type, numel::Int64, size::Tuple{Int64,Int64})::Vector{type}
    return [type(undef, size) for _ in 1:numel]
end

"""
    load_imgs(; input::String, image_type::String)

Load all images of type `image_type` (either `"truecolor"` or `"falsecolor"`) in `input` into a vector.
"""
function load_imgs(; input::String, image_type::Union{Symbol,String})
    return [
        float64.(load(joinpath(input, f))) for
        f in readdir(input) if contains(f, string(image_type))
    ]
end

function load_truecolor_imgs(; input::String)
    return load_imgs(; input=input, image_type="truecolor")
end

function load_falsecolor_imgs(; input::String)
    return load_imgs(; input=input, image_type="falsecolor")
end

"""
    sharpen(truecolor_imgs::Vector{Matrix{Float64}}, landmask_no_dilate::Matrix{Bool})

Sharpen truecolor images with the non-dilated landmask applied. Returns a vector of sharpened images.

"""
function sharpen(
    truecolor_imgs::Vector{Matrix{RGB{Float64}}}, landmask_no_dilate::BitMatrix
)
    @info "Sharpening truecolor images..."
    return [imsharpen(img, landmask_no_dilate) for img in truecolor_imgs]
end

function cloudmask(; input::String, output::String)::Vector{BitMatrix}
    # find falsecolor imgs in input dir
    fc = [img for img in readdir(input) if contains(img, "falsecolor")] # fc is sorted
    total_fc = length(fc)
    @info "Found $(total_fc) falsecolor images in $input. 
    Cloudmasking false color images..."

    # Preallocate container for the cloudmasks
    fc_img = IceFloeTracker.float64.(IceFloeTracker.load(joinpath(input, fc[1]))) # read in the first one to retrieve size
    sz = size(fc_img)
    cloudmasks = [BitMatrix(undef, sz) for _ in 1:total_fc]

    # Do the first one because it's loaded already
    cloudmasks[1] = IceFloeTracker.create_cloudmask(fc_img)
    # and now the rest
    for i in 2:total_fc
        img = IceFloeTracker.float64.(IceFloeTracker.load(joinpath(input, fc[i])))
        cloudmasks[i] = IceFloeTracker.create_cloudmask(img)
    end
    return cloudmasks
end

"""
    disc_ice_water(
    falsecolor_imgs::Vector{Matrix{RGB{Float64}}},
    normalized_imgs::Vector{Matrix{Gray{Float64}}},
    cloudmasks::Vector{BitMatrix},
    landmask::BitMatrix,
)

Generate vector of ice/water discriminated images from the collection of falsecolor, sharpened truecolor, and cloudmask images using the study area landmask. Returns a vector of ice/water masks.

"""
function disc_ice_water(
    falsecolor_imgs::Vector{Matrix{RGB{Float64}}},
    normalized_imgs::Vector{Matrix{Gray{Float64}}},
    cloudmasks::Vector{BitMatrix},
    landmask::BitMatrix,
)
    return [
        IceFloeTracker.discriminate_ice_water(fc_img, norm_img, landmask, cldmsk) for
        (fc_img, norm_img, cldmsk) in zip(falsecolor_imgs, normalized_imgs, cloudmasks)
    ]
end

"""
    sharpen_gray(
    sharpened_imgs::Vector{Matrix{Float64}},
    landmask::AbstractArray{Bool},
)

Apply the landmask to the collection of sharpened truecolor images and return a gray colorview of the collection.
"""
function sharpen_gray(
    sharpened_imgs::Vector{Matrix{Float64}}, landmask::AbstractArray{Bool}
)
    return [IceFloeTracker.imsharpen_gray(img, landmask) for img in sharpened_imgs]
end

function get_ice_labels(
    falsecolor_imgs::Vector{Matrix{RGB{Float64}}}, landmask::AbstractArray{Bool}
)
    return [
        IceFloeTracker.find_ice_labels(fc_img, landmask) for fc_img in falsecolor_imgs
    ]
end

"""
    preprocess(; truecolor_image, falsecolor_image, landmask_imgs)

Preprocess and segment floes in `truecolor_image` and `falsecolor_image` images using the landmasks  `landmask_imgs`. Returns a boolean matrix with segmented floes for feature extraction.

# Arguments
- `truecolor_image::T`: truecolor image to be processed
- `falsecolor_image::T`: falsecolor image to be processed
- `landmask_imgs`: named tuple with dilated and non-dilated landmask images
"""
function preprocess(
    truecolor_image::T,
    falsecolor_image::T,
    landmask_imgs::NamedTuple{(:dilated, :non_dilated),Tuple{BitMatrix,BitMatrix}},
) where {T<:Matrix{RGB{Float64}}}
    @info "Building cloudmask"
    cloudmask = create_cloudmask(falsecolor_image)

    # 2. Intermediate images
    @info "Finding ice labels"
    ice_labels = IceFloeTracker.find_ice_labels(
        falsecolor_image, landmask_imgs.non_dilated
    )

    @info "Sharpening truecolor image"
    # a. apply imsharpen to truecolor image using non-dilated landmask
    sharpened_truecolor_image = IceFloeTracker.imsharpen(
        truecolor_image, landmask_imgs.non_dilated
    )
    # b. apply imsharpen to sharpened truecolor img using dilated landmask
    sharpened_gray_truecolor_image = IceFloeTracker.imsharpen_gray(
        sharpened_truecolor_image, landmask_imgs.dilated
    )

    @info "Normalizing truecolor image"
    normalized_image = IceFloeTracker.normalize_image(
        sharpened_truecolor_image, sharpened_gray_truecolor_image, landmask_imgs.dilated
    )

    # Discriminate ice/water
    @info "Discriminating ice/water"
    ice_water_discrim = IceFloeTracker.discriminate_ice_water(
        falsecolor_image, normalized_image, copy(landmask_imgs.dilated), cloudmask
    )

    # 3. Segmentation
    @info "Segmenting floes part 1/3"
    segA = IceFloeTracker.segmentation_A(
        IceFloeTracker.segmented_ice_cloudmasking(ice_water_discrim, cloudmask, ice_labels)
    )

    # segmentation_B
    @info "Segmenting floes part 2/3"
    segB = IceFloeTracker.segmentation_B(sharpened_gray_truecolor_image, cloudmask, segA)

    # Process watershed in parallel using Folds
    @info "Building watersheds"
    # container_for_watersheds = [landmask_imgs.non_dilated, similar(landmask_imgs.non_dilated)]
    watersheds_segB = Folds.map(
        IceFloeTracker.watershed_ice_floes, [segB.not_ice_bit, segB.ice_intersect]
    )
    # reuse the memory allocated for the first watershed
    watersheds_segB[1] .= IceFloeTracker.watershed_product(watersheds_segB...)

    # segmentation_F
    @info "Segmenting floes part 3/3"
    return IceFloeTracker.segmentation_F(
        segB.not_ice,
        segB.ice_intersect,
        watersheds_segB[1],
        ice_labels,
        cloudmask,
        landmask_imgs.dilated,
    )
end

"""
    preprocess(; truedir::T, fcdir::T, lmdir::T, passtimesdir::T, output::T) where {T<:AbstractString}

Preprocess and segment floes in all images in `truedir` and `fcdir` using the landmasks in `lmdir` according to the ordering in the passtimes obtained from the SOIT tool. Save the segmented floes and time deltas between images to `output`.

# Arguments
- `truedir`: directory with truecolor images to be processed
- `fcdir`: directory with falsecolor images to be processed
- `lmdir`: directory with dilated and non-dilated landmask images
- `passtimesdir`: path to SOIT file with satellite passtimes
- `output`: output directory
"""
function preprocess(; truedir::T, fcdir::T, lmdir::T, passtimesdir::T, output::T) where {T<:AbstractString}

    soitdf = process_soit(passtimesdir)

    # 1. Get references to images
    falsecolor_refs, truecolor_refs = [mkfilenames(soitdf, colorspace) for colorspace in ["falsecolor", "truecolor"]]
    landmask_imgs = deserialize(joinpath(lmdir, "generated_landmask.jls"))
    numimgs = length(truecolor_refs)

    # 2. Preprocess
    @info "Preprocessing"
    _img = loadimg(; dir=truedir, fname=truecolor_refs[1])
    sz = size(_img)
    truecolor_container = cache_vector(typeof(_img), numimgs, sz)
    falsecolor_container = copy(truecolor_container)
    segmented_floes = cache_vector(BitMatrix, numimgs, sz)

    @info "Processing images"
    Threads.@threads for i in eachindex(truecolor_refs)
        @info "Processing image $i of $numimgs"
        truecolor_container[i] .= loadimg(; dir=truedir, fname=truecolor_refs[i])
        falsecolor_container[i] .= loadimg(; dir=fcdir, fname=falsecolor_refs[i])
        try
            segmented_floes[i] .= preprocess(
                truecolor_container[i], falsecolor_container[i], landmask_imgs
            )
        catch e
            if isa(e, ArgumentError)
                @warn "ArgumentError: $(e.msg).\nIs there excessive cloud coverage? Skipping image $i."
            end
            segmented_floes[i] .= BitMatrix(zeros(size(falsecolor_container[i])))
        end
    end

    # 3. Save
    @info "Serializing segmented floes/time deltas/image file names/pass times"
    serialize(joinpath(output, "segmented_floes.jls"), segmented_floes)
    serialize(joinpath(output, "timedeltas.jls"), getdeltat(soitdf.pass_time))
    serialize(joinpath(output, "filenames.jls"), (truecolor=truecolor_refs, falsecolor=falsecolor_refs))
    serialize(joinpath(output, "passtimes.jls"), soitdf.pass_time)
    return nothing
end
