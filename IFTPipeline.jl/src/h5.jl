"""
    makeh5filename(imgfname, ts)

Generate the name of the HDF5 file from the name of the source image and the estimated satellite overpass time. The name of the HDF5 file is of the form `YYYYmmddTHHMM.labeled_image.250m.h5` where `YYYYmmddTHHMM` is the estimated satellite overpass time formatted string.
"""
function makeh5filename(imgfname, ts)
    fname = Dates.format(ts, "YYYYmmddTHHMM") * "." * split(imgfname, '.'; limit=2)[end]
    return replace(fname, "truecolor" => "labeled_image", "tiff" => "h5")
end

"""
    choose_dtype(mx)

Choose the appropriate unsigned integer type based on a maximum value.

# Arguments

  * `mx`: Maximum value to be stored in the unsigned integer type.

# Returns
    
      * `UInt8` if `mx` is less than or equal to 255.
      * `UInt16` if `mx` is less than or equal to 65535.
      * `UInt32` if `mx` is less than or equal to 4294967295.
"""
function choose_dtype(mx)
    types = [UInt8, UInt16, UInt32]
    for (i, t) in enumerate(types)
        b = 2^(2^(2 + i)) - 1
        if mx <= b
            return t
        end
    end
end


"""
    makeh5files(pathtosampleimg, resdir)

Package the results of the IceFloeTracker pipeline in `resdir` into individual HDF5 files in `resdir/hdf5-files`. 

This function expects the following files to be present in `resdir`: `filenames.jls`, `passtimes.jls`, `segmented_floes.jls`, and `floe_props.jls`. These files are generated by the `IceFloeTracker` pipeline.

# Arguments:

  * `pathtosampleimg`: Path to a sample image in the truecolor resource folder. This is used to extract the coordinate reference system (CRS) and the latitude and longitude coordinates of the image pixels.
  * `resdir`: Path to the directory containing the results of the IceFloeTracker pipeline.
  * `iftversion`: This is automatically pulled into the function from an environment variable.

# File structure
Each HDF5 file has the following structure:

```
    🗂️ HDF5.File: (read-only) YYYYmmddTHHMM.sat.labeled_image.250m.h5
    ├─ 🏷️ contact
    ├─ 🏷️ crs
    ├─ 🏷️ fname_falsecolor
    ├─ 🏷️ fname_truecolor
    ├─ 🏷️ iftversion
    ├─ 🏷️ reference
    ├─ 📂 floe_properties
    │  ├─ 🏷️ Description of labeled_image
    │  ├─ 🏷️ Description of properties
    │  ├─ 🔢 column_names
    │  ├─ 🔢 labeled_image
    │  └─ 🔢 properties
    └─ 📂 index
    ├─ 🔢 latitude
    ├─ 🔢 longitude
    ├─ 🔢 time
    ├─ 🔢 x
    └─ 🔢 y
```
# The `floe_properties` and `index` group

The `floe_properties` group contains a floe properties matrix `properties` for `labeled_image` and associated `column_names`.
The `index` group contains the spatial coordinates in the source image coordinate reference system (default NSIDC polar stereographic, meters) and geographic coordinates (latitude and longitude, decimal degrees). Estimated satellite overpass time `time` is provided in Unix timestamp format (seconds since 1970-01-01 00:00 UTC).
"""
function makeh5files(; pathtosampleimg::String, resdir::String, iftversion=IceFloeTracker.IFTVERSION)
    latlondata = getlatlon(pathtosampleimg)

    ptpath = joinpath(resdir, "passtimes.jls")
    passtimes = deserialize(ptpath)
    ptsunix = Int64.(Dates.datetime2unix.(passtimes))

    fnpath = joinpath(resdir, "filenames.jls")
    truecolor_refs, falsecolor_refs = deserialize(fnpath)

    floespath = joinpath(resdir, "segmented_floes.jls") # for labeled_image
    floes = deserialize(floespath)

    colstodrop = [:row_centroid, :col_centroid, :min_row, :min_col, :max_row, :max_col]
    propspath = joinpath(resdir, "floe_props.jls")
    props = deserialize(propspath)
    for df in props
        converttounits!(df, latlondata, colstodrop)
    end

    h5dir = joinpath(resdir, "hdf5-files")
    mkpath(h5dir)
    for (i, fname) in enumerate(truecolor_refs)
        fname = makeh5filename(fname, passtimes[i])
        fnamepath = joinpath(h5dir, fname)
        h5open(fnamepath, "w") do file
            # Add top-level attributes
            attrs(file)["fname_falsecolor"] = falsecolor_refs[i]
            attrs(file)["fname_truecolor"] = truecolor_refs[i]
            attrs(file)["iftversion"] = string(iftversion)
            attrs(file)["crs"] = latlondata["crs"]
            attrs(file)["reference"] = "https://doi.org/10.1016/j.rse.2019.111406"
            attrs(file)["contact"] = "mmwilhelmus@brown.edu"

            g = create_group(file, "index")
            g["time"] = ptsunix[i]
            g["x"] = latlondata["X"]
            g["y"] = latlondata["Y"]

            g = create_group(file, "floe_properties")
            g["properties"] = Matrix(props[i])
            attrs(g)["Description of properties"] = """Generated using the `regionprops` function from the `skimage` package. See https://scikit-image.org/docs/0.20.x/api/skimage.measure.html#regionprops

            Area units (`area`, `convex_area`) are in sq. kilometers, length units (`minor_axis_length`, `major_axis_length`, and `perimeter`) in kilometers, and `orientation` in radians (see the description of properties attribute.) Latitude and longitude coordinates are in degrees, and the stereographic coordinates`x` and `y` are in meters relative to the NSIDC north polar stereographic projection.
            """

            g["column_names"] = names(props[i])
            comps = label_components(floes[i], trues(3, 3))
            mx = maximum(comps)
            T = choose_dtype(mx)
            g["labeled_image"] = T.(comps)

            attrs(g)["Description of labeled_image"] = "Connected components of the segmented floe image using a 3x3 structuring element. The property matrix consists of the properties of each connected component."
        end
    end
    return nothing
end