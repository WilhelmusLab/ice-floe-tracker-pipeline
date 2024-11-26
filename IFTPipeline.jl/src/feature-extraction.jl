"""
    extractfeatures(bw::T; minarea, maxarea, features)

Extract features from the labeled image `bw` using the area thresholds in `area_threshold` and the vector of features `features`. Returns a DataFrame of the extracted features.

# Arguments
- `bw``: A labeled image.
- `minarea` and `maxarea`: The minimum and maximum (inclusive) areas of the floes to extract.
- `features`: A vector of the features to extract.

# Example
```jldoctest; setup = :(using IceFloeTracker, Random)
julia> Random.seed!(123);

julia> bw_img = rand(Bool, 5, 50)
5×50 Matrix{Bool}:
 0  0  1  0  1  0  1  0  1  0  1  0  0  0  0  0  0  1  1  0  1  0  1  1  1  1  1  0  0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  1  0  1
 1  0  0  0  1  1  0  0  0  1  0  0  0  0  0  0  0  0  0  0  1  1  0  0  1  0  0  0  0  1  1  1  1  1  0  1  0  1  1  0  1  1  1  1  0  0  1  1  1  1
 0  1  1  1  1  1  0  0  1  0  1  1  0  1  1  1  1  1  1  1  1  0  0  1  0  1  1  1  0  0  0  0  1  0  0  0  0  0  1  0  0  0  1  0  1  0  0  0  0  0
 0  1  0  0  1  1  1  0  0  0  1  0  1  0  1  0  1  0  0  1  1  1  1  0  0  1  0  0  0  0  1  0  0  0  1  1  1  0  0  1  1  1  0  1  0  0  0  0  1  0
 0  1  1  1  1  0  0  0  1  0  1  0  0  1  0  1  0  0  1  1  0  1  1  0  1  1  0  1  1  0  0  0  1  0  0  0  0  1  0  0  0  1  1  0  1  0  1  1  1  0

julia> features = ["centroid", "area", "major_axis_length", "minor_axis_length", "convex_area", "bbox"]
6-element Vector{String}:
 "centroid"
 "area"
 "major_axis_length"
 "minor_axis_length"
 "convex_area"
 "bbox"

julia> minarea, maxarea = 1, 5
 (1, 5)

julia> IFTPipeline.extractfeatures(bw_img; minarea=minarea, maxarea=maxarea, features=features)
8×10 DataFrame
 Row │ area   min_row  min_col  max_row  max_col  row_centroid  col_centroid  convex_area  major_axis_length  minor_axis_length 
     │ Int32  Int32    Int32    Int32    Int32    Int64         Int64         Int32        Float64            Float64
─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │     1        1        3        1        3             1             3            1            0.0                0.0
   2 │     1        5        9        5        9             5             9            1            0.0                0.0
   3 │     2        1       18        1       19             1            19            2            2.0                0.0
   4 │     2        5       28        5       29             5            29            2            2.0                0.0
   5 │     1        4       31        4       31             4            31            1            0.0                0.0
   6 │     1        5       33        5       33             5            33            1            0.0                0.0
   7 │     4        4       35        5       38             4            37            5            4.68021            1.04674
   8 │     4        4       47        5       49             5            48            5            3.4641             1.41421
```
"""
function extractfeatures(
    floes::AbstractArray{<:Union{Integer,Bool}};
    minarea::Int64=350,
    maxarea::Int64=90000,
    features::Union{Vector{Symbol},Vector{<:AbstractString}}
)::DataFrame
    # assert the first area threshold is less than the second
    minarea >= maxarea &&
        throw(ArgumentError("The minimum area must be less than the maximum area."))

    floes = isa(eltype(floes), Bool) ? label_components(floes, trues(3, 3)) : floes
    props = regionprops_table(floes; properties=features)
    @debug "loaded $props"

    # filter by area using the area thresholds
    return props[minarea.<=props.area.<=maxarea, :]
end

function extractfeatures(;
    input::String, output::String, minarea::String, maxarea::String, features::String
)
    # parse minarea and minarea as Int64
    minarea = parse(Int64, minarea)
    maxarea = parse(Int64, maxarea)

    # parse the features
    features = split(features)

    # load segmented images in input directory
    segmented_floes = deserialize(joinpath(input, "segmented_floes.jls"))

    props = Vector{DataFrame}(undef, length(segmented_floes))

    f =
        x -> IFTPipeline.extractfeatures(
            x; minarea=minarea, maxarea=maxarea, features=features
        )
    for i in eachindex(segmented_floes)
        props[i] = f(segmented_floes[i])
    end

    # serialize the props vector to the output directory 
    serialize(joinpath(output, "floe_props.jls"), props)
    return nothing
end

function extractfeatures_single(;
    input::String, output::String, minarea::Int64, maxarea::Int64, features::Array{String}
)
    @info "Loading segmented floes from $input"
    labeled_floes = Int.(load_labeled_img(input))

    @info "Extracting features from each floe: $features"
    props = IFTPipeline.extractfeatures(labeled_floes; minarea=minarea, maxarea=maxarea, features=features)

    @info "Extracted properties:"
    @info props

    @info "Writing to $output"
    FileIO.save(output, props)
    return nothing
end

"""
    load_labeled_img(path)

Load an unsigned integer image from a file.

See also: save_labeled_img
"""
function load_labeled_img(path::AbstractString)
    image = FileIO.load(path)
    image_reinterpreted = convert_uint_from_gray(image)
    return image_reinterpreted
end

"""
    save_labeled_img(image, path)

Save an unsigned integer image to an image file.

See also: load_labeled_img
"""
function save_labeled_img(image::AbstractArray{<:Integer}, path::AbstractString)
    image_reinterpreted = convert_gray_from_uint(image)
    FileIO.save(path, image_reinterpreted)
    return path
end

int_to_fixedpoint_map = Dict(
    UInt8 => N0f8,
    Int8 => Q0f7,
    UInt16 => N0f16,
    Int16 => Q0f15,
    UInt32 => N0f32,
    Int32 => Q0f31,
    UInt64 => N0f64,
    Int64 => Q0f63
)

"""
    convert_gray_from_uint(image)

Convert an image from an unsigned integer format into a fixed-point Gray format.

See also: convert_uint_from_gray
"""

function convert_gray_from_uint(image::AbstractArray{<:Integer})
    img_type = eltype(image)
    
    # Lookup the target type in the dictionary. If not found call the do block to throw the warning
    target_type = get(int_to_fixedpoint_map, img_type) do
        error("Missing mapping for $img_type in convert_gray_from_uint")
    end
    image_reinterpreted  = Gray.(reinterpret.(target_type, image))
    return image_reinterpreted
end

fixedpoint_to_int_map = Dict(Gray{value} => key for (key, value) in int_to_fixedpoint_map)

"""
    convert_uint_from_gray(image)

Convert an image from a fixed-point Gray format into integers.

See also: convert_gray_from_uint
"""
function convert_uint_from_gray(image)
    image_reinterpreted = rawview(channelview(image))
    img_type = eltype(image)
    target_type = get(fixedpoint_to_int_map, img_type) do
        error("Missing mapping for $img_type in convert_uint_from_gray")
    end
    image_recast = target_type.(image_reinterpreted)
    return image_recast
end