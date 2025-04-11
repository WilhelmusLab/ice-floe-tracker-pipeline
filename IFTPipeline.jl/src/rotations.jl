using DataFrames
using TimeZones
using CSV

"""
Make a CSV of pairwise rotations between floes detected on adjacent days. 

Loads the floes from the `input` CSV file, and uses the columns:
- `floe` ID
- `satellite` name
- `mask` – the binary mask (choose a column using argument `mask_column`)
- `passtime` in ISO8601 format (with trailing Z or +00:00), e.g. 2022-09-11T09:21:00+00:00  (choose a column using argument `time_column`)


Returns a CSV with one row per floe comparison. 
In the following, `i=1` means the earlier observation, `i=2` the later.

Columns returned:
- `ID` of the floe
- Angle measures `theta_<deg,rad>` – angle between floe image in degrees or radians
- Time measurements:
  - `passtime<i>` – which UTC time measurement `i`'s overpass occurred
  - `delta_time_sec` – number of seconds between overpass in the two measurements
  - `omega_<deg,rad>_per_<sec,hour,day>` – mean angular velocity of rotation in degrees or radians per second hour or day.
- Any columns listed in `additional_columns` will also be included like `<name><i>` in the output
  - `mask<i>` – the binary mask used for the measurement is always last.
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
