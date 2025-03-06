"""
    process_soit(passtimesdir::String)

Process the [SOIT](https://github.com/WilhelmusLab/SOIT-Satellite-Overpass-Identification-Tool) output file.

The SOIT output file is a csv file with columns :Date, :sat1, :sat2, ... :satn, where each row is a pass time for the satellites listed in the columns. The resulting DataFrame has columns `:sat` and `:pass_time` sorted by :pass_time.

# Arguments
- `passtimesdir::String`: The directory containing the SOIT output file
"""
function process_soit(passtimesdir::String)
    # check there is a file at passtimesdir starting with "passtimes_lat" with extension .csv
    pth = filter(x -> occursin(r"^passtimes_lat.*\.csv$", x), readdir(passtimesdir))
    isempty(pth) &&
        error("No csv file found at $passtimesdir starting with 'passtimes_lat'")
    length(pth) > 1 &&
        error("More than one csv file found at $passtimesdir starting with 'passtimes_lat'")

    data, cols = readdlm(joinpath(passtimesdir, pth[1]), ','; header=true)
    df = DataFrame(data, vec(cols))[1:(end - 1), :]

    # filter out rows with value "" in the first column
    filter!(row -> row[1] != "", df)

    # get all but the "Date" column names from df
    oldsatnames = [nm for nm in names(df) if nm != "Date"]
    newsatnames = [lowercase(split(nm)[1]) for nm in oldsatnames]

    rename!(df, oldsatnames .=> newsatnames)

    df = stack(df, newsatnames)

    rename!(df, :value => :pass_time, :variable => :sat, :Date => :date)

    # Convert to dates
    df[!, :date] = Date.(df[:, :date], dateformat"mm-dd-yyyy")
    df[!, :pass_time] = Time.(df[:, :pass_time])
    df[!, :pass_time] = DateTime.(df[:, :date], df[:, :pass_time])

    # drop the date column
    select!(df, Not(:date))

    sort!(df, :pass_time)

    return df
end

"""
    getdeltat(dates)

Get the time difference between each date in `dates` in minutes.
"""
function getdeltat(dates)
    return [round(t.value / 60_000) for t in abs.(diff(dates))]
end
"""
    mkfilenames(df, colorspace="truecolor", grid="250m", ext="tiff")

Create image filenames based on the SOIT output file.

# Arguments
- `df::DataFrame`: The cleaned SOIT output file with columns :sat and :pass_time
- `colorspace::String`: The colorspace, either "falsecolor" or "truecolor"
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
