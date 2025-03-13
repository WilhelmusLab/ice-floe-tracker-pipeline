using DataFrames
using TimeZones
using Dates
using CSV

# Base.tryparse(::Type{ZonedDateTime}, str) = ZonedDateTime
# default_format(::Type{ZonedDateTime}) = Format("yyyy-mm-dd\\THH:MM:SS.sZ")

"""
Make a CSV of pairwise rotations between floes detected on adjacent days. 

Loads the floes from the `input` CSV file, and uses the columns:
- `floe` ID
- `satellite` name
- `mask` – the binary mask (choose a column using argument `mask_column`)
- `passtime` in ISO8601 format (with trailing Z or +00:00), e.g. 2022-09-11T09:21:00+00:00  (choose a column using argument `time_column`)
- `date` of the overpass in YYYY-MM-DD format

Returns a CSV with one row per floe comparison. 
In the following, `i=1` means the earlier observation, `i=2` the later.

Columns returned:
- `ID` of the floe
- Angle measures `theta_<deg,rad>` – angle between floe image in degrees or radians
- Time measurements:
  - `delta_time_sec` – number of seconds between overpass in the two measurements
  - `omega_<deg,rad>_per_<sec,hour,day>` – mean angular velocity of rotation in degrees or radians per second hour or day.
- Metadata 
  - `satellite<i>` – which satellite measurement `i` was from
  - `date<i>` – which date measurement `i` was taken
  - `datetime<i>` – which UTC time measurement `i`'s overpass occurred
- Original data
  - `mask<i>` – the binary mask used for the measurement
"""
function get_rotation_single(;
    input::String, output::String, mask_column=:mask, time_column=:passtime
)
    input_df = DataFrame(CSV.File(input))

    input_df[!, mask_column] = eval.(Meta.parse.(input_df[:, mask_column]))
    input_df[!, time_column] = ZonedDateTime.(input_df[:, time_column])

    results = []
    for row in eachrow(input_df)
        append!( # adds the 0 – n measurements from `get_rotation_measurements` to the results array
            results,
            get_rotation_measurements(
                row, input_df; mask_column=mask_column, time_column=time_column
            ),
        )
    end
    results_df = DataFrame(results)
    @info results_df

    FileIO.save(output, results_df)
    return results_df
end

function get_rotation_measurements(
    measurement::DataFrameRow, df::DataFrame; mask_column, time_column
)
    filtered_df = subset(
        df,
        :ID => ByRow(==(measurement[:ID])),
        :date => ByRow(==(measurement[:date] - Dates.Day(1))),
    )

    results = [
        get_rotation_measurements(
            earlier_measurement, measurement; mask_column, time_column
        ) for earlier_measurement in eachrow(filtered_df)
    ]

    return results
end

function get_rotation_measurements(
    row1::DataFrameRow, row2::DataFrameRow; mask_column, time_column
)
    (_, theta_deg) = IceFloeTracker.mismatch(row1[mask_column], row2[mask_column])
    theta_rad = deg2rad(theta_deg)

    dt = row2[time_column] - row1[time_column]
    dt_sec = dt / Dates.Second(1)
    dt_hour = dt / Dates.Hour(1)
    dt_day = dt / Dates.Day(1)

    omega_deg_per_sec = (theta_deg) / (dt_sec)
    omega_deg_per_hour = (theta_deg) / (dt_hour)
    omega_deg_per_day = (theta_deg) / (dt_day)

    omega_rad_per_sec = (theta_rad) / (dt_sec)
    omega_rad_per_hour = (theta_rad) / (dt_hour)
    omega_rad_per_day = (theta_rad) / (dt_day)

    return (
        ID=row1.ID,
        theta_deg,
        theta_rad,
        delta_time_sec=dt_sec,
        omega_deg_per_sec,
        omega_deg_per_hour,
        omega_deg_per_day,
        omega_rad_per_sec,
        omega_rad_per_hour,
        omega_rad_per_day,
        satellite1=row1.satellite,
        satellite2=row2.satellite,
        date1=row1.date,
        date2=row2.date,
        datetime1=row1[time_column],
        datetime2=row2[time_column],
        mask1=row1[mask_column],
        mask2=row2[mask_column],
    )
end
