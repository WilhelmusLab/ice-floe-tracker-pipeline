using DataFrames
using TimeZones
using CSV

"""
Make a CSV of pairwise rotations between floes detected on adjacent days. 

Loads the floes from the `input` CSV file. Columns required:
- floe `ID`
- `mask` – the binary mask
- `passtime` in ISO8601 format:
  Needs trailing `Z` or `+00:00`, e.g. `2022-09-11T09:21:00Z` or `2022-09-11T09:21:00+00:00`

Other columns often included:
- `satellite` name

Returns a CSV with one row per floe comparison. 
In the following, `i=1` means the earlier observation, `i=2` the later.

Columns returned:
- Angle measures:
  - `theta_deg` – angle between floe image in degrees
  - `theta_rad` – angle between floe image in radians
- Time measurements:
  - `dt_sec` – number of seconds between overpass in the two measurements
  - `omega_rad_per_sec` – angular velocity of rotation in radians per second.\
  - `omega_rad_per_day` – angular velocity of rotation in radians per day.
  - `omega_deg_per_day` – angular velocity of rotation in radians per day.
- Metadata: all of the columns from from the input with the column name suffix `i` including:
  - `ID<i>`
  - `mask<i>`
  - `passtime<i>`
  - if available: `satellite<i>`.
"""
function measure_rotation(;
    input::String, output::String, id_column=:ID, image_column=:mask, time_column=:passtime
)
    input_df = DataFrame(CSV.File(input))

    input_df[!, image_column] = eval.(Meta.parse.(input_df[:, image_column]))
    input_df[!, time_column] = ZonedDateTime.(String.(input_df[:, time_column]))

    results_df = get_rotation_measurements(input_df; id_column, image_column, time_column)
    @info results_df

    FileIO.save(output, results_df)
    return results_df
end
