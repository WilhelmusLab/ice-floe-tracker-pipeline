using DataFrames
using TimeZones
using Dates
using CSV
using Interpolations
using OrderedCollections

# Base.tryparse(::Type{ZonedDateTime}, str) = ZonedDateTime
# default_format(::Type{ZonedDateTime}) = Format("yyyy-mm-dd\\THH:MM:SS.sZ")

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
function get_rotation_single(;
    input::String,
    output::String,
    mask_column=:mask,
    time_column=:passtime,
    additional_columns=[],
)
    input_df = DataFrame(CSV.File(input))

    input_df[!, mask_column] = eval.(Meta.parse.(input_df[:, mask_column]))
    input_df[!, time_column] = ZonedDateTime.(String.(input_df[:, time_column]))
    input_df[!, :_date] = Date.(input_df[:, time_column])

    results = []
    for row in eachrow(input_df)
        append!( # adds the 0 – n measurements from `get_rotation_measurements` to the results array
            results,
            get_rotation_measurements(
                row, input_df; mask_column, time_column, additional_columns
            ),
        )
    end
    results_df = DataFrame(results)
    @info results_df

    FileIO.save(output, results_df)
    return results_df
end

function get_rotation_measurements(
    measurement::DataFrameRow, df::DataFrame; mask_column, time_column, additional_columns
)
    filtered_df = subset(
        df,
        :ID => ByRow(==(measurement[:ID])),
        :_date => ByRow(==(measurement[:_date] - Dates.Day(1))),
    )

    results = [
        get_rotation_measurements(
            earlier_measurement, measurement; mask_column, time_column, additional_columns
        ) for earlier_measurement in eachrow(filtered_df)
    ]

    return results
end

function get_rotation_measurements(
    row1::DataFrameRow,
    row2::DataFrameRow;
    mask_column,
    time_column,
    rotation_function=get_rotation_shape_difference,
    additional_columns=[],
)
    theta_rad = rotation_function(row1[mask_column], row2[mask_column])
    theta_deg = rad2deg(theta_rad)

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

    result = OrderedDict([
        "ID" => row1.ID,
        "theta_deg" => theta_deg,
        "theta_rad" => theta_rad,
        String(time_column) * "1" => row1[time_column],
        String(time_column) * "2" => row2[time_column],
        "delta_time_sec" => dt_sec,
        "omega_deg_per_sec" => omega_deg_per_sec,
        "omega_deg_per_hour" => omega_deg_per_hour,
        "omega_deg_per_day" => omega_deg_per_day,
        "omega_rad_per_sec" => omega_rad_per_sec,
        "omega_rad_per_hour" => omega_rad_per_hour,
        "omega_rad_per_day" => omega_rad_per_day,
    ])

    for colname in hcat(additional_columns, [mask_column])
        result[String(colname) * "1"] = row1[colname]
        result[String(colname) * "2"] = row2[colname]
    end

    return result
end

greaterthan05(x) = x .> 0.5 # used for the image resize step and for binarizing images
function imrotate_bin(x, r)
    return greaterthan05(collect(imrotate(x, r, axes(x); method=BSpline(Constant()))))
end
function imrotate_bin_nocrop(x, r)
    return greaterthan05(collect(imrotate(x, r; method=BSpline(Constant()))))
end

# Functions used for the SD minimization
"""
Pad images by zeros based on the size of the larger of the two images.
"""
function pad_images(im1, im2)
    max1 = maximum(size(im1))
    max2 = maximum(size(im2))

    n = Int64(ceil(maximum([max1, max2])))
    im1_padded = collect(padarray(im1, Fill(0, (n, n), (n, n))))
    im2_padded = collect(padarray(im2, Fill(0, (n, n), (n, n))))
    return im1_padded, im2_padded
end

"""
Calculate the centroid of a binary image. If 'rounded', return the
nearest integer.
"""
function compute_centroid(im; rounded=false)
    xi = 0
    yi = 0
    R = sum(im .> 0)
    n, m = size(im)
    for ii in range(1, n)
        for jj in range(1, m)
            if im[ii, jj] > 0
                xi += ii
                yi += jj
            end
        end
    end

    x0, y0 = sum(xi) / R, sum(yi) / R
    if rounded
        return round(Int32, x0), round(Int32, y0)
    else
        return x0, y0
    end
end

"""
Align images by selecting and cropping so that r1, c1 and r2, c2 are the center.
These values are expected to be the (integer) centroid of the image. These images
should already be padded so that there is no danger of cutting into the floe shape.
"""
function crop_to_shared_centroid(im1, im2)
    r1, c1 = compute_centroid(im1; rounded=true)
    r2, c2 = compute_centroid(im2; rounded=true)

    n1, m1 = size(im1)
    n2, m2 = size(im2)
    new_halfn = minimum([minimum([r1, n1 - r1]), minimum([r2, n2 - r2])])
    new_halfm = minimum([minimum([c1, m1 - c1]), minimum([c2, m2 - c2])])

    # check notation: how does julia interpret start and end of array index?
    im1_cropped = im1[
        (1 + r1 - new_halfn):(r1 + new_halfn), (1 + c1 - new_halfm):(c1 + new_halfm)
    ]
    im2_cropped = im2[
        (1 + r2 - new_halfn):(r2 + new_halfn), (1 + c2 - new_halfm):(c2 + new_halfm)
    ]

    return im1_cropped, im2_cropped
end

"""
Computes the shape difference between im_reference and im_target for each angle (degrees) in test_angles.
The reference image is held constant, while the target image is rotated. The test_angles are interpreted
as the angle of rotation from target to reference, so to find the best match, we rotate the reverse
direction. A perfect match at angle A would imply im_target is the same shape as if im_reference was
rotated by A degrees.
"""
function shape_difference_rotation(im_reference, im_target, test_angles)
    imref_padded, imtarget_padded = pad_images(im_reference, im_target)
    shape_differences = Array{
        NamedTuple{(:angle, :shape_difference),Tuple{Float64,Float64}}
    }(
        undef, length(test_angles)
    )
    # shape_differences = zeros((length(test_angles), 2))
    init_props = regionprops_table(label_components(im_reference))[1, :] # assumption only one object in image!
    idx = 1
    # r_init, c_init = compute_centroid(imref_padded, rounded=true)
    for angle in test_angles
        # try rotating image back by angle
        imtarget_rotated = imrotate_bin(imtarget_padded, -(-angle))

        im1, im2 = crop_to_shared_centroid(imref_padded, imtarget_rotated)

        # Check here that im1 and im2 sizes are the same
        # Could also add check that the images are nonempty
        # These checks could go inside the crop_to_shared_ccentroid function
        if isequal.(prod(size(im1)), prod(size(im2)))
            a_not_b = im1 .> 0 .&& isequal.(im2, 0)
            b_not_a = im2 .> 0 .&& isequal.(im1, 0)
            shape_difference = sum(a_not_b .|| b_not_a)
            shape_differences[idx] = (; angle, shape_difference)
        else
            @warn("Warning: shapes not equal\n")
            @warn(angle, size(im1), size(im2), "\n")
            shape_differences[idx] = (; angle, shape_difference=NaN)
        end
        idx += 1
    end
    return shape_differences
end

function get_rotation_shape_difference(
    mask1,
    mask2;
    test_angles=sort(reverse(range(; start=-π, stop=π, step=π / 36)[1:(end - 1)]); by=abs),
)
    shape_differences = shape_difference_rotation(mask1, mask2, test_angles)
    best_match = argmin((x) -> x.shape_difference, shape_differences)
    return best_match.angle
end
