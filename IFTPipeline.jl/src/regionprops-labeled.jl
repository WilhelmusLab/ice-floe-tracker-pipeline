using Images


"""
    cropfloe(floesimg, label)

Crops the floe from `floesimg` with the label `label`, adding a one pixel border of zeros and converting to a BitMatrix.
"""
function cropfloe(floesimg::Array{Int}, label::Int)
    #= Remove any pixels not corresponding to that numbered floe 
    (each segment has a different integer) =#
    floe_area = floesimg .== label
    @info "mask: $floe_area"

    # Crop the floe to the size of the floe.
    nonzero = x -> x > 0
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

    floe_area_padded = parent(padarray(floe_area_cropped, Fill(0, (1, 1))))
    @info "floe_area_padded: $floe_area_padded"

    return BitMatrix(floe_area_padded)
end


"""
    cropfloe(floesimg, min_row, min_col, max_row, max_col)

Crops the floe delimited by `min_row`, `min_col`, `max_row`, `max_col`, from the floe image `floesimg`.
"""
function cropfloe(floesimg::BitMatrix, min_row::Int, min_col::Int, max_row::Int, max_col::Int)
    #= 
    Crop the floe using bounding box data in props.
    Note: Using a view of the cropped floe was considered but if there were multiple components in the cropped floe, the source array with the floes would be modified. =#
    prefloe = floesimg[min_row:max_row, min_col:max_col]

    #= Check if more than one component is present in the cropped image.
    If so, keep only the largest component by removing all on pixels not in the largest component =#
    components = label_components(prefloe, trues(3, 3))

    if length(unique(components)) > 2
        mask = IceFloeTracker.bwareamaxfilt(components .> 0)
        prefloe[.!mask] .= 0
    end
    return prefloe
end


"""
    cropfloe(floesimg, min_row, min_col, max_row, max_col, label)

Crops the floe from `floesimg` with the label `label`, returning the region bounded by `min_row`, `min_col`, `max_row`, `max_col`, and converting to a BitMatrix.
"""
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


"""
    cropfloe(floesimg, props, i)

Crops the floe delimited by the bounding box data in `props` at index `i` from the floe image `floesimg`.

If the dataframe has bounding box data `min_row`, `min_col`, `max_row`, `max_col`, but no `label`, then returns the largest contiguous component.

If the dataframe has bounding box data `min_row`, `min_col`, `max_row`, `max_col`, and a `label`, then returns the component with the label. In this case, `floesimg` must be an Array{Int}.

If the dataframe has only a `label` and no bounding box data, then returns the component with the label, padded by one cell of zeroes on all sides. In this case, `floesimg` must be an Array{Int}.


"""
function cropfloe(floesimg::Union{Array{Int},BitMatrix}, props::DataFrame, i::Int)
    props_row = props[i, :]
    colnames = names(props_row)
    if "min_row" in colnames && "min_col" in colnames && "max_row" in colnames && "max_col" in colnames
        if "label" in colnames
            return cropfloe(
                floesimg,
                props_row.min_row,
                props_row.min_col,
                props_row.max_row,
                props_row.max_col,
                props_row.label
            )
        else
            floesimg_bitmatrix = floesimg .> 0
            return cropfloe(
                floesimg_bitmatrix,
                props_row.min_row,
                props_row.min_col,
                props_row.max_row,
                props_row.max_col
            )
        end
    elseif "label" in colnames
        return cropfloe(floesimg, props_row.label)
    end
end




