"""
    cropfloe(floesimg, props, i)

Crops the floe delimited by the bounding box data in `props` at index `i` from the floe image `floesimg`.
"""
function cropfloe(floesimg::Array{Int}, props::DataFrame, i::Int)
    #= 
    Crop the floe using bounding box data in props.
    Note: Using a view of the cropped floe was considered but if there were multiple components in the cropped floe, the source array with the floes would be modified. =#
    return cropfloe(floesimg=floesimg, min_row=props.min_row[i], max_row=props.max_row[i], min_col=props.min_col[i], max_col=props.max_col[i], label=props.label[i])
end

function cropfloe(; floesimg::Array{Int}, min_row::Int, max_row::Int, min_col::Int, max_col::Int, label::Int)
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