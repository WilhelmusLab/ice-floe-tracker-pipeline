"""
    cropfloe(floesimg, props, i)

Crops the floe delimited by the bounding box data in `props` at index `i` from the floe image `floesimg`.
"""
function cropfloe(floesimg::Array{Int}, props::DataFrame, i::Int)
    #= 
    Crop the floe using bounding box data in props.
    Note: Using a view of the cropped floe was considered but if there were multiple components in the cropped floe, the source array with the floes would be modified. =#
    prefloe = floesimg[props.min_row[i]:props.max_row[i], props.min_col[i]:props.max_col[i]]
    @info "prefloe: $prefloe"

    #= Remove any pixels not corresponding to that numbered floe 
    (each segment has a different integer) =#
    floe_area = prefloe .== props.label[i]
    @info "mask: $floe_area"
    
    prefloe[floe_area] .= 1
    prefloe[.!floe_area] .= 0
    @info "final prefloe: $prefloe"

    return prefloe
end

