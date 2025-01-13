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
        falsecolor_image, landmask_imgs.dilated
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

"""
    preprocess_single(; truecolor::T, falsecolor::T, landmask::T, landmask_dilated::T, output::T) where {T<:AbstractString}

Preprocess and segment floes in a single view. Save the segmented floes to `output`.

# Arguments
- `truecolor`: path to truecolor image
- `falsecolor`: path to falsecolor image
- `landmask`: path to landmask image
- `landmask_dilated`: path to dilated landmask image
- `output`: path to output file 
"""
function preprocess_single(; truecolor::T, falsecolor::T, landmask::T, landmask_dilated::T, output::T) where {T<:AbstractString}

    @info "Processing images: $truecolor, $falsecolor, $landmask"
    truecolor_img = loadimg(; dir=dirname(truecolor), fname=basename(truecolor))
    falsecolor_img = loadimg(; dir=dirname(falsecolor), fname=basename(falsecolor))

    # TODO: make symmetric landmask saving/loading functions
    landmask = (
        dilated=BitMatrix(FileIO.load(landmask_dilated)),
        non_dilated=BitMatrix(FileIO.load(landmask)),
    )

    @info "Removing alpha channel if it exists"
    rgb_truecolor_img = RGB.(truecolor_img)
    rgb_falsecolor_img = RGB.(falsecolor_img)

    @info "Segmenting floes"
    segmented_floes = preprocess(rgb_truecolor_img, rgb_falsecolor_img, landmask)

    @info "Labeling floes"
    labeled_floes = label_components(segmented_floes)
    _dtype = choose_dtype(maximum(labeled_floes))
    labeled_floes_cast = convert(Array{_dtype}, labeled_floes)
    
    @info "Writing segmented floes to $output"
    save_labeled_img(labeled_floes_cast, output)

    return nothing
end

"""
    preprocess_tiling_single(; truecolor::T, falsecolor::T, landmask::T, landmask_dilated::T, output::T, <other keyword arguments>) where {T<:AbstractString}

Preprocess and segment floes in a single view. Save the segmented floes to `segmented` and the labeled floes to `labeled`.

# Arguments
- `truecolor`: path to truecolor image
- `falsecolor`: path to falsecolor image
- `landmask`: path to landmask image
- `landmask_dilated`: path to dilated landmask image
- `segmented`: path to segmented output file 
- `labeled`: path to labeled output file
- `tile_rblocks::Int=8`: 
- `tile_cblocks::Int=8`: 
- `ice_labels_prelim_threshold::Float64=110.0`: 
- `ice_labels_band_7_threshold::Float64=200.0`: 
- `ice_labels_band_2_threshold::Float64=190.0`: 
- `ice_labels_ratio_lower::Float64=0.0`: 
- `ice_labels_ratio_upper::Float64=0.75`: 
- `adapthisteq_white_threshold::Float64=25.5,`: 
- `adapthisteq_entropy_threshold::Float64=4,`: 
- `adapthisteq_white_fraction_threshold::Float64=0.4`: 
- `gamma::Float64=1`: 
- `gamma_factor::Float64=1`: 
- `gamma_threshold::Float64=220`: 
- `unsharp_mask_radius::Int=10,`: 
- `unsharp_mask_amount::Float64=2.0,`: 
- `unsharp_mask_factor::Float64=255.0`: 
- `brighten_factor::Float64=0.1`: 
- `prelim_icemask_radius::Int=10,`: 
- `prelim_icemask_amount::Int=2,`: 
- `prelim_icemask_factor::Float64=0.5`: 
- `icemask_band_7_threshold::Int=5`: 
- `icemask_band_2_threshold::Int=230`: 
- `icemask_band_1_threshold::Int=240`: 
- `icemask_band_7_threshold_relaxed::Int=10`: 
- `icemask_band_1_threshold_relaxed::Int=190`: 
- `icemask_possible_ice_threshold::Int=75`: 
- `icemask_n_clusters::Int=3`: 

"""
function preprocess_tiling_single(
    ; 
    truecolor::T, 
    falsecolor::T, 
    landmask_dilated::T, 
    segmented::T,
    labeled::T,

    # Tiling parameters
    tile_rblocks=8,
    tile_cblocks=8,

    # Ice labels thresholds
    ice_labels_prelim_threshold=110.0,
    ice_labels_band_7_threshold=200.0,
    ice_labels_band_2_threshold=190.0,
    ice_labels_ratio_lower=0.0,
    ice_labels_ratio_upper=0.75,

    # Adaptive histogram equalization parameters
    adapthisteq_white_threshold=25.5, 
    adapthisteq_entropy_threshold=4, 
    adapthisteq_white_fraction_threshold=0.4,

    # Gamma parameters
    gamma=1,
    gamma_factor=1,
    gamma_threshold=220,

    # Unsharp mask parameters
    unsharp_mask_radius=10, 
    unsharp_mask_amount=2.0, 
    unsharp_mask_factor=255.0,

    # Brighten parameters
    brighten_factor=0.1,

    # Preliminary ice mask parameters
    prelim_icemask_radius=10, 
    prelim_icemask_amount=2, 
    prelim_icemask_factor=0.5,

    # Main ice mask parameters
    icemask_band_7_threshold=5,
    icemask_band_2_threshold=230,
    icemask_band_1_threshold=240,
    icemask_band_7_threshold_relaxed=10,
    icemask_band_1_threshold_relaxed=190,
    icemask_possible_ice_threshold=75,
    icemask_n_clusters=3,

    ) where {T<:AbstractString}

    @info "Processing images: $truecolor, $falsecolor, $landmask_dilated"
    truecolor_img = loadimg(; dir=dirname(truecolor), fname=basename(truecolor))
    falsecolor_img = loadimg(; dir=dirname(falsecolor), fname=basename(falsecolor))

    # TODO: make symmetric landmask saving/loading functions
    landmask_dilated=BitMatrix(FileIO.load(landmask_dilated))
    
    # Invert the landmasks – in the tiling version of the code, 
    # the landmask is expected to be the other polarity compared with
    # the non-tiling version.
    landmask = (
        dilated=.!landmask_dilated,
    )

    @info "Remove alpha channel if it exists"
    rgb_truecolor_img = RGB.(truecolor_img)
    rgb_falsecolor_img = RGB.(falsecolor_img)

    @info "Get tile coordinates"
    tiles = IceFloeTracker.get_tiles(
        rgb_truecolor_img; 
        rblocks=tile_rblocks, 
        cblocks=tile_cblocks
    )
    @debug tiles

    @info "Set ice labels thresholds"
    ice_labels_thresholds = (
        prelim_threshold=ice_labels_prelim_threshold,
        band_7_threshold=ice_labels_band_7_threshold,
        band_2_threshold=ice_labels_band_2_threshold,
        ratio_lower=ice_labels_ratio_lower,
        ratio_upper=ice_labels_ratio_upper,
        use_uint8=true,
    )
    @debug ice_labels_thresholds

    @info "Set adaptive histogram parameters"
    adapthisteq_params = (
        white_threshold=adapthisteq_white_threshold,
        entropy_threshold=adapthisteq_entropy_threshold,
        white_fraction_threshold=adapthisteq_white_fraction_threshold,
    )
    @debug adapthisteq_params

    @info "Set gamma parameters"
    adjust_gamma_params = (
        gamma=gamma,
        gamma_factor=gamma_factor,
        gamma_threshold=gamma_threshold,
    )
    @debug adjust_gamma_params

    @info "Set structuring elements"
    # This isn't tunable in the underlying code right now, 
    # so just use the defaults
    structuring_elements = IceFloeTracker.structuring_elements
    @debug structuring_elements

    @info "Set unsharp mask params"
    unsharp_mask_params = (
        radius=unsharp_mask_radius,
        amount=unsharp_mask_amount,
        factor=unsharp_mask_factor
    )
    @debug unsharp_mask_params

    @info "Set brighten factor"
    @debug brighten_factor
    
    @info "Set preliminary ice masks params"
    prelim_icemask_params = (
        radius=prelim_icemask_radius,
        amount=prelim_icemask_amount,
        factor=prelim_icemask_factor,
    )
    @debug prelim_icemask_params
    
    @info "Set ice masks params"
    ice_masks_params = (
        band_7_threshold=icemask_band_7_threshold,
        band_2_threshold=icemask_band_2_threshold,
        band_1_threshold=icemask_band_1_threshold,
        band_7_threshold_relaxed=icemask_band_7_threshold_relaxed,
        band_1_threshold_relaxed=icemask_band_1_threshold_relaxed,
        possible_ice_threshold=icemask_possible_ice_threshold,
        k=icemask_n_clusters, # number of clusters for kmeans segmentation
        factor=255, # normalization factor to convert images to uint8
    )
    @debug ice_masks_params

    
    @info "Segment floes"
    segmented_floes = IceFloeTracker.preprocess_tiling(
        n0f8.(rgb_falsecolor_img), 
        n0f8.(rgb_truecolor_img), 
        landmask,
        tiles,
        ice_labels_thresholds,
        adapthisteq_params,
        adjust_gamma_params,
        structuring_elements,
        unsharp_mask_params,
        ice_masks_params,
        prelim_icemask_params,
        brighten_factor,
    )

    @info "Write segmented floes to $segmented"
    FileIO.save(segmented, segmented_floes)

    @info "Label floes"
    labeled_floes = label_components(segmented_floes)
    _dtype = choose_dtype(maximum(labeled_floes))
    labeled_floes_cast = convert(Array{_dtype}, labeled_floes)
    
    @info "Write labeled floes to $labeled"
    save_labeled_img(labeled_floes_cast, labeled)

    return nothing
end