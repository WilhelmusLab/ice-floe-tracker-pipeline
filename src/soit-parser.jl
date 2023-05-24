function process_soit(soitpth::String)
    data, cols = readdlm(soitpth, ','; header=true)
    df = DataFrame(data, vec(cols))

    # rename the columns "Aqua pass time" and "Terra pass time" to :aqua and :terra
    DataFrames.rename!(df, "Aqua pass time" => :aqua, "Terra pass time" => :terra)

    # filter out rows with value "" in the first column
    filter!(row -> row[1] != "", df)

    # stack df on the second and third columns
    df = stack(df, [:aqua, :terra])

    # rename :value as :pass_time, and :variable as :sat
    rename!(df, :value => :pass_time, :variable => :sat, :Date => :date)

    # reorder the columns to put :satellite first
    df = df[:, [:sat, :date, :pass_time]]

    # Convert to dates
    df[!, :date] = Date.(df[:, :date], dateformat"mm-dd-yyyy")
    df[!, 3] = Time.(df[:, :pass_time])
    df[!, 3] = DateTime.(df[:, :date], df[:, :pass_time])

    # drop the date column
    select!(df, Not(:date))

    #sort df by :pass_time
    sort!(df, :pass_time)

    return df
end

getdeltat(dates) = [round(t.value / 6000) for t in abs.(diff(dates))]

"""
    mkfilenames(df, colorspace="truecolor", grid="250m", ext="tiff")

Create image filenames based on the SOIT output file.

# Arguments
- `df::DataFrame`: The cleaned SOIT output file with columns :sat and :pass_time
- `colorspace::String`: The colorspace, either "reflectance" or "truecolor"
- `grid::String`: The grid size, either "250m" or "1km"
- `ext::String`: The file extension, either "tiff" or "jpg"

# Examples
```julia
julia> df = DataFrame(sat=["aqua", "terra"], pass_time=[DateTime(2020, 6, 10, 12, 0, 0), DateTime(2020, 6, 11, 12, 0, 0)])
julia> mkfilenames(df)
2-element Vector{String}:
 "20200610.aqua.truecolor.250m.tiff"
 "20200611.terra.truecolor.250m.tiff"
```
"""
function mkfilenames(df, colorspace="truecolor", grid="250m", ext="tiff")
    dates = replace.(string.(Date.(df.pass_time)), r"-" => "") # remove dashes
    tail = join([colorspace, grid, ext], ".")
    return string.(dates, ".", df.sat, ".", tail)
end
