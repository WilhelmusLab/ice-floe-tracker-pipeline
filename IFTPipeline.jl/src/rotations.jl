using DataFrames
using TimeZones

function get_rotation_single(; input::String, output::String)
    input_df = DataFrame(CSV.File(input))
    array_mask_column = :evaluated_mask
    input_df[:, array_mask_column] = eval.(Meta.parse.(input_df[:, :mask]))
    pass_time_column = :passtime_parsed
    input_df[:, pass_time_column] = ZonedDateTime.(input_df[:, :passtime])

    results = []
    for row in eachrow(input_df)
        append!(
            results,
            get_rotation_measurements(
                row,
                input_df;
                mask_column=array_mask_column,
                datetime_column=pass_time_column,
            ),
        )
    end
    @info results
    results_df = DataFrame(results)

    FileIO.save(output, results_df)
    return results_df
end

function get_rotation_pair(row1::DataFrameRow, row2::DataFrameRow; column=:mask)
    (_, rot) = IceFloeTracker.mismatch(row1[column], row2[column])
    return rot
end

function get_rotation_measurements(
    row::DataFrameRow, df::DataFrame; mask_column, datetime_column
)
    filtered_df = subset(
        df, :ID => ByRow(==(row[:ID])), :date => ByRow(==(row[:date] - Dates.Day(1)))
    )
    @info filtered_df

    results = []
    for comparison_row in eachrow(filtered_df)
        rot = get_rotation_pair(row, comparison_row; column=mask_column)
        push!(
            results,
            (
                ID=(row.ID),
                rot=rot,
                satellite1=comparison_row.satellite,
                satellite2=row.satellite,
                date1=comparison_row.date,
                date2=row.date,
                datetime1=comparison_row[datetime_column],
                datetime2=row[datetime_column],
                dt=convert(
                    Dates.Second, row[datetime_column] - comparison_row[datetime_column]
                ),
                mask1=comparison_row[mask_column],
                mask2=row[mask_column],
            ),
        )
    end

    return results
end