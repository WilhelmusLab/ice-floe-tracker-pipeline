using TimeZones: ZonedDateTime

@testset "hdf5 export" begin
    @testset "normal case" begin
        testlisteq = (a, b) -> @test Set(a) == Set(b)
        pathtosampleimg = joinpath(
            @__DIR__, "test_inputs/input_pipeline/20220914.aqua.falsecolor.250m.tiff"
        )
        resdir = joinpath(dirname(pathtosampleimg), "h5")

        originalbbox = (latitude=[81, 79], longitude=[-22, -12])

        latlondata = latlon(pathtosampleimg)

        getcorners(m) = [m[1, 1], m[end, end]]
        latcorners = getcorners(latlondata[:latitude])
        loncorners = getcorners(latlondata[:longitude])

        ptpath = joinpath(resdir, "passtimes.jls")
        passtimes = deserialize(ptpath)
        ptsunix = Int64.(Dates.datetime2unix.(passtimes))

        fnpath = joinpath(resdir, "filenames.jls")
        truecolor_refs, falsecolor_refs = deserialize(fnpath)

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
            @test attrs(fid)["iftversion"] == string(IceFloeTracker.IFTVERSION)
            @test attrs(fid)["fname_falsecolor"] == falsecolor_refs[1]
            @test attrs(fid)["fname_truecolor"] == truecolor_refs[1]
            @test attrs(fid)["crs"] == latlondata[:crs]

            # groups
            testlisteq(keys(fid), ["floe_properties", "index"])
            keys_index = [k for k in keys(fid["index"]) if k ∉ ["latitude", "longitude"]]
            testlisteq(keys_index, ["time", "x", "y"])
            testlisteq(
                keys(fid["floe_properties"]),
                ["column_names", "labeled_image", "properties"],
            )

            # check index group datasets
            g = fid["index"]
            t = read(g["time"])
            x = read(g["x"])
            y = read(g["y"])

            @test t == ptsunix[1]
            @test x == latlondata[:X]
            @test y == latlondata[:Y]

            # check floe_properties group datasets
            g = fid["floe_properties"]
            colnames = read(g["column_names"])
            lb = read(g["labeled_image"])
            props = read(g["properties"])

            testlisteq(
                colnames,
                [
                    "area",
                    "convex_area",
                    "major_axis_length",
                    "minor_axis_length",
                    "orientation",
                    "perimeter",
                    "latitude",
                    "longitude",
                    "x",
                    "y",
                ],
            )

            @test typeof(lb) == Matrix{UInt8}
            @test typeof(props) == Matrix{Float64}
            close(fid)

            @test_throws "can't be represented" choose_dtype(-1)
            @test choose_dtype(100) == UInt8
            @test choose_dtype(300) == UInt16
            @test choose_dtype(70_000) == UInt32
            @test choose_dtype(BigInt(2)^64 - 1) == UInt64
            @test choose_dtype(BigInt(2)^64) == UInt128
            @test choose_dtype(BigInt(2)^128 - 1) == UInt128
            @test_throws "can't be represented" choose_dtype(BigInt(2)^128)
        end

        # clean up
        rm(dirname(h5path); recursive=true)
    end
    @testset "empty props" begin
        example_data_dir = joinpath(test_data_dir, "cloudy")
        IFTPipeline.makeh5files_single(;
            passtime=ZonedDateTime("2006-05-13T14:55:34Z"),
            truecolor=joinpath(example_data_dir, "truecolor.tiff"),
            falsecolor=joinpath(example_data_dir, "falsecolor.tiff"),
            labeled=joinpath(example_data_dir, "labeled.tiff"),
            props=joinpath(example_data_dir, "labeled.props.csv"),
            output="example.h5", #mktemp()[1],
        )
    end
end
