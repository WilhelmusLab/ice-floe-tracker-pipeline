using DataFrames

function get_rotation_single(; input::String, output::String)
    df = DataFrame(CSV.File(input))
    array_mask_column = :evaluated_mask
    df[:, array_mask_column] = eval.(Meta.parse.(df[:, :mask]))
    rot = get_rotation_pair(df[1, :], df[2, :]; column=array_mask_column)
    @info rot
    FileIO.save(output, df)
    return df
end

function get_rotation_pair(row1::DataFrameRow, row2::DataFrameRow; column=:mask)
    (mm, rot) = IceFloeTracker.mismatch(row1[column], row2[column])
    return rot
end