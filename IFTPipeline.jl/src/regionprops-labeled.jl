using Images
"""
    cropfloe(floesimg, props, i)

Crops the floe delimited by the bounding box data in `props` at index `i` from the floe image `floesimg`.
"""
function cropfloe(floesimg::Array{Int}, props::DataFrame, i::Int)
    #= 
    Crop the floe using bounding box data in props.
    Note: Using a view of the cropped floe was considered but if there were multiple components in the cropped floe, the source array with the floes would be modified. =#
    return cropfloe(floesimg, props.min_row[i], props.min_col[i], props.max_row[i], props.max_col[i], props.label[i])
end

function cropfloe(floesimg::Array{Int}, label::Int)
    #= Remove any pixels not corresponding to that numbered floe 
    (each segment has a different integer) =#
    floe_area = floesimg .== label
    @info "mask: $floe_area"
    
    # Crop the floe to the size of the floe.
    nonzero = x -> x>0
    rows = 2
    cols = 1
    row_sums = count(floe_area, dims=rows)
    col_sums = count(floe_area, dims=cols)
    @info "row_sums: $row_sums, col_sums: $col_sums"
    
    min_row = findfirst(nonzero, row_sums)[cols]
    min_col = findfirst(nonzero, col_sums)[rows]
    max_row = findlast(nonzero, row_sums)[cols]
    max_col = findlast(nonzero, col_sums)[rows]
    @info "($min_row, $min_col), ($max_row, $max_col)"
    
    floe_area_cropped = floe_area[min_row:max_row, min_col:max_col]
    @info "floe_area_cropped: $floe_area_cropped"

    floe_area_padded = parent(padarray(floe_area_cropped, Fill(0,(1,1))))
    @info "floe_area_padded: $floe_area_padded"

    return BitMatrix(floe_area_padded)
end

function cropfloe(floesimg::Array{Int}, min_row::Int, min_col::Int, max_row::Int, max_col::Int, label::Int)
    #= 
    Crop the floe using bounding box data in props.
    Note: Using a view of the cropped floe was considered but if there were multiple components in the cropped floe, the source array with the floes would be modified. =#
    prefloe = floesimg[min_row:max_row, min_col:max_col]
    @info "prefloe: $prefloe"

    #= Remove any pixels not corresponding to that numbered floe 
    (each segment has a different integer) =#
    floe_area = prefloe .== label
    @info "mask: $floe_area"
    
    prefloe[floe_area] .= 1
    prefloe[.!floe_area] .= 0
    @info "final prefloe: $prefloe"

    return prefloe
end