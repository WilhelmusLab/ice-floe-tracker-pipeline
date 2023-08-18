testlisteq = (a, b) -> @test Set(a) == Set(b)
pathtosampleimg = joinpath(@__DIR__, "test_inputs/input_pipeline/20220914.aqua.reflectance.250m.tiff")
resdir = joinpath(dirname(pathtosampleimg), "h5")

originalbbox = (latitude=[81, 79], longitude=[-22, -12])

latlondata = getlatlon(pathtosampleimg)

getcorners(m) = [m[1, 1], m[end, end]]
latcorners = getcorners(latlondata["latitude"])
loncorners = getcorners(latlondata["longitude"])

_iftversion = IFTPipeline.iftversion[1]

ptpath = joinpath(resdir, "passtimes.jls")
passtimes = deserialize(ptpath)
ptsunix = Int64.(Dates.datetime2unix.(passtimes))

fnpath = joinpath(resdir, "filenames.jls")
truecolor_refs, reflectance_refs = deserialize(fnpath)

floespath = joinpath(resdir, "segmented_floes.jls") # for labeled_image
floes = deserialize(floespath)

propspath = joinpath(resdir, "floe_props.jls")
props = deserialize(propspath)

lb = label_components(floes[1])

makeh5files(; pathtosampleimg, resdir)

h5path = joinpath(resdir, "hdf5-files", "20220914T1244.aqua.labeled_image.250m.h5")

@testset "h5.jl" begin

    # validate computed lat/lon corners
    @test all(originalbbox.latitude .≈ round.(latcorners))
    @test all(originalbbox.longitude .≈ round.(loncorners))


    # open h5 file
    fid = h5open(h5path, "r")

    @test typeof(fid) == HDF5.File

    # top level attributes
    @test attrs(fid)["iftversion"] == _iftversion
    @test attrs(fid)["fname_reflectance"] == reflectance_refs[1]
    @test attrs(fid)["fname_truecolor"] == truecolor_refs[1]
    @test attrs(fid)["crs"] == latlondata["crs"]

    # groups
    testlisteq(keys(fid), ["floe_properties", "index"])
    testlisteq(keys(fid["index"]), ["latitude", "longitude", "time", "x", "y"])
    testlisteq(keys(fid["floe_properties"]), ["column_names", "labeled_image", "properties"])

    # check index group datasets
    g = fid["index"]
    lat = read(g["latitude"])
    lon = read(g["longitude"])
    t = read(g["time"])
    x = read(g["x"])
    y = read(g["y"])

    @test lat == latlondata["latitude"]
    @test lon == latlondata["longitude"]
    @test t == ptsunix[1]
    @test x == latlondata["X"]
    @test y == latlondata["Y"]

    # check floe_properties group datasets
    g = fid["floe_properties"]
    colnames = read(g["column_names"])
    lb = read(g["labeled_image"])
    props = read(g["properties"])

    testlisteq(colnames, ["area", "convex_area", "major_axis_length", "minor_axis_length", "orientation", "perimeter", "latitude", "longitude", "x", "y"])

    @test typeof(lb) == Matrix{Int64}
    @test typeof(props) == Matrix{Float64}
    close(fid)
end

# clean up
rm(dirname(h5path), recursive=true)
