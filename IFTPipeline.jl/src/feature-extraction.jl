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
    bw::T;
    minarea::Int64=350,
    maxarea::Int64=90000,
    features::Union{Vector{Symbol},Vector{<:AbstractString}}
)::DataFrame where {T<:AbstractArray{Bool}}
    # assert the first area threshold is less than the second
    minarea >= maxarea &&
        throw(ArgumentError("The minimum area must be less than the maximum area."))

    props = regionprops_table(label_components(bw, trues(3, 3)); properties=features)

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
