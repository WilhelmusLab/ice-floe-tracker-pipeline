#!/usr/bin/env julia

using ArgParse
using IceFloeTracker
using IFTPipeline
using Serialization

function mkclipreprocess!(settings)
    @add_arg_table! settings["preprocess"] begin
        "--truedir", "-t"
        help = "Truecolor image directory"
        required = true

        "--fcdir", "-r"
        help = "Falsecolor image directory"
        required = true

        "--lmdir", "-l"
        help = "Land mask image directory"
        required = true

        "--passtimesdir", "-p"
        help = "Pass times directory"
        required = true

        "--output", "-o"
        help = "Output directory"
        required = true
    end
    return nothing
end

function mkclipreprocess_single!(settings)
    @add_arg_table! settings["preprocess_single"] begin
        "--truecolor", "-t"
        help = "Truecolor image file (.tiff)"
        required = true

        "--falsecolor", "-r"
        help = "Falsecolor image file (.tiff)"
        required = true

        "--landmask", "-l"
        help = "Landmask image file (.tiff)"
        required = true

        "--landmask-dilated", "-d"
        help = "Landmask image file (dilated, .tiff)"
        required = true

        "--output", "-o"
        help = "Path to output segmented image file (.tiff)"
        required = true
        
    end
    return nothing
end

function mkcli_preprocess_tiling_single!(settings)
    @add_arg_table! settings["preprocess_tiling_single"] begin
        "--truecolor", "-t"
        help = "Truecolor image file (.tiff)"
        required = true

        "--falsecolor", "-r"
        help = "Falsecolor image file (.tiff)"
        required = true

        "--landmask-dilated", "-d"
        help = "Landmask image file (dilated, .tiff)"
        required = true

        "--segmented", "-s"
        help = "Path to output segmented image file (.tiff)"
        required = true
        
        "--labeled", "-l"
        help = "Path to output labeled image file (.tiff)"
        required = true


        # Tiling parameters
        
        "--tile-rblocks"
        default = 8
        arg_type = Int
        required = false

        "--tile-cblocks"
        default = 8
        arg_type = Int
        required = false


        # Ice labels thresholds
        
        "--ice-labels-prelim-threshold"
        default = 110.0
        arg_type = Float64
        required = false

        "--ice-labels-band-7-threshold"
        default = 200.0
        arg_type = Float64
        required = false

        "--ice-labels-band-2-threshold"
        default = 190.0
        arg_type = Float64
        required = false

        "--ice-labels-ratio-lower"
        default = 0.0
        arg_type = Float64
        required = false

        "--ice-labels-ratio-upper"
        default = 0.75
        arg_type = Float64
        required = false


        # Adaptive histogram equalization parameters
        
        "--adapthisteq-white-threshold"
        default = 25.5
        arg_type = Float64
        required = false

        "--adapthisteq-entropy-threshold"
        default = 4
        arg_type = Float64
        required = false

        "--adapthisteq-white-fraction-threshold"
        default = 0.4
        arg_type = Float64
        required = false


        # Gamma parameters
        
        "--gamma"
        default = 1
        arg_type = Float64
        required = false

        "--gamma-factor"
        default = 1
        arg_type = Float64
        required = false

        "--gamma-threshold"
        default = 220
        arg_type = Float64
        required = false


        # Unsharp mask parameters
        
        "--unsharp-mask-radius"
        default = 10
        arg_type = Int
        required = false

        "--unsharp-mask-amount"
        default = 2.0
        arg_type = Float64
        required = false

        "--unsharp-mask-factor"
        default = 255.0
        arg_type = Float64
        required = false


        # Brighten parameters
        
        "--brighten-factor"
        default  = 0.1
        arg_type = Float64
        required = false


        # Preliminary ice mask parameters
        
        "--prelim-icemask-radius"
        default = 10
        arg_type = Int
        required = false

        "--prelim-icemask-amount"
        default = 2
        arg_type = Int
        required = false

        "--prelim-icemask-factor"
        default = 0.5
        arg_type = Float64
        required = false


        # Main ice mask parameters
        
        "--icemask-band-7-threshold"
        default = 5
        arg_type = Int
        required = false

        "--icemask-band-2-threshold"
        default = 230
        arg_type = Int
        required = false

        "--icemask-band-1-threshold"
        default = 240
        arg_type = Int
        required = false

        "--icemask-band-7-threshold-relaxed"
        default = 10
        arg_type = Int
        required = false

        "--icemask-band-1-threshold-relaxed"
        default = 190
        arg_type = Int
        required = false

        "--icemask-possible-ice-threshold"
        default = 75
        arg_type = Int
        required = false

        "--icemask-n-clusters"
        default = 3
        arg_type = Int
        required = false

    end
    return nothing
end

function mkcliextract!(settings)
    @add_arg_table! settings["extractfeatures"] begin
        "--input", "-i"
        help = "Input image directory"
        required = true

        "--output", "-o"
        help = "Output image directory"
        required = true

        "--minarea"
        help = "Minimum area (in pixels) of ice floes to extract"
        default = "350"

        "--maxarea"
        help = "Maximum area (in pixels) of ice floes to extract"
        default = "90000"

        "--features", "-f"
        help = """Features to extract. Format: "feature1 feature2". For an extensive list of extractable features see https://scikit-image.org/docs/stable/api/skimage.measure.html#skimage.measure.regionprops:~:text=The%20following%20properties%20can%20be%20accessed%20as%20attributes%20or%20keys"""
        default = "centroid area major_axis_length minor_axis_length convex_area bbox orientation perimeter"
    end
    return nothing
end

function mkcliextract_single!(settings)
    @add_arg_table! settings["extractfeatures_single"] begin
        "--input", "-i"
        help = "Input image"
        required = true

        "--output", "-o"
        help = "Output file (csv)"
        required = true

        "--minarea"
        help = "Minimum area (in pixels) of ice floes to extract"
        arg_type = Int
        default = 350

        "--maxarea"
        help = "Maximum area (in pixels) of ice floes to extract"
        arg_type = Int
        default = 90000

        "--features", "-f"
        help = """Features to extract. Format: "feature1 feature2". For an extensive list of extractable features see https://scikit-image.org/docs/stable/api/skimage.measure.html#skimage.measure.regionprops:~:text=The%20following%20properties%20can%20be%20accessed%20as%20attributes%20or%20keys"""
        nargs = '+'
        arg_type = String
        default = ["label", "centroid", "area", "major_axis_length", "minor_axis_length", "convex_area", "bbox", "orientation", "perimeter"]
    end
    return nothing
end

function mkclimakeh5!(settings)
    @add_arg_table! settings["makeh5files"] begin
        "--pathtosampleimg", "-p"
        help = "Path to a sample image with coordinate reference system (CRS) and latitude and longitude coordinates of image pixels"
        arg_type = String

        "--resdir", "-r"
        help = "Path to the directory containing serialized results of the IceFloeTracker pipeline"
        arg_type = String
    end
    return nothing
end

function mkclimakeh5_single!(settings)
    @add_arg_table! settings["makeh5files_single"] begin
        "--iftversion"
        help = "Version number of the IceFloeTracker.jl package"
        required = false
        arg_type = String

        "--passtime"
        help = "Satellite pass time"
        required = true
        arg_type = DateTime

        "--truecolor"
        help = "Path to truecolor image"
        required = true
        arg_type = String

        "--falsecolor"
        help = "Path to falsecolor image"
        required = true
        arg_type = String

        "--labeled"
        help = "Path to labeled image"
        required = true
        arg_type = String

        "--props"
        help = "Path to extracted features (csv)"
        required = true
        arg_type = String

        "--output"
        help = "Output file"
        required = true
    end
    return nothing
end

function mkclitrack!(settings)
    add_arg_group!(settings["track"], "arguments")
    @add_arg_table! settings["track"] begin
        "--imgs"
        help = "Path to object with segmented images"
        required = true

        "--props"
        help = "Path to object with extracted features"
        required = true

        "--passtimes"
        help = "Path to object with satellite pass times"
        required = true

        "--latlon"
        help = "Path to geotiff image with latitude/longitude data"
        required = true

        "--output", "-o"
        help = "Output directory"
        required = true
    end

    add_arg_group!(settings["track"], "optional arguments")
    @add_arg_table! settings["track"] begin
        "--params"
        help = "Path to TOML file with algorithm parameters"

        "--dist"
        help = "Distance threholds to use for pairing floes"
        default = "200 250 300"

        "--dt-thresh"
        help = "Time thresholds to use for pairing floes"
        default = "30 100 1300"

        "--Sminimumarea"
        help = "Minimum area for small floes"
        arg_type = Float64
        default = 350

        "--Sarearatio"
        help = "Area ratio threshold for small floes"
        arg_type = Float64
        default = 0.18

        "--Smajaxisratio"
        help = "Major axis ratio threshold for small floes"
        arg_type = Float64
        default = 0.1

        "--Sminaxisratio"
        help = "Minor axis ratio threshold for small floes"
        arg_type = Float64
        default = 0.12

        "--Sconvexarearatio"
        help = "Convex area ratio threshold for small floes"
        arg_type = Float64
        default = 0.14

        "--Lminimumarea"
        help = "Minimum area for large floes"
        arg_type = Float64
        default = 1200

        "--Larearatio"
        help = "Area ratio threshold for large floes"
        arg_type = Float64
        default = 0.28

        "--Lmajaxisratio"
        help = "Major axis ratio threshold for large floes"
        arg_type = Float64
        default = 0.1

        "--Lminaxisratio"
        help = "Minor axis ratio threshold for large floes"
        arg_type = Float64
        default = 0.15

        "--Lconvexarearatio"
        help = "Convex area ratio threshold for large floes"
        arg_type = Float64
        default = 0.14

        # matchcorr computation
        "--mxrot"
        help = "Maximum rotation"
        arg_type = Int64
        default = 10

        "--psi"
        help = "Minimum psi-s correlation"
        arg_type = Float64
        default = 0.95

        "--sz"
        help = "Minimum side length of floe mask"
        arg_type = Int64
        default = 16

        "--comp"
        help = "Size comparability"
        arg_type = Float64
        default = 0.25

        "--mm"
        help = "Maximum registration mismatch"
        arg_type = Float64
        default = 0.22

        # Goodness of match
        "--corr"
        help = "Mininimun psi-s correlation"
        arg_type = Float64
        default = 0.68

        "--large_floe_area"
        help = "Large floe area mismatch threshold"
        arg_type = Float64
        default = 0.236

        "--small_floe_area"
        help = "Small floe area mismatch threshold"
        arg_type = Float64
        default = 0.18
    end
    return nothing
end

function mkclitrack_single!(settings)
    add_arg_group!(settings["track_single"], "arguments")
    @add_arg_table! settings["track_single"] begin
        "--imgs"
        help = "Paths to segmented images"
        required = true
        nargs = '+'
        arg_type = String

        "--props"
        help = "Paths to extracted features"
        required = true
        nargs = '+'
        arg_type = String

        "--passtimes"
        help = "Path to object with satellite pass times"
        required = true
        nargs = '+'
        arg_type = DateTime

        "--latlon"
        help = "Path to geotiff image with latitude/longitude data"
        required = true

        "--output", "-o"
        help = "Output file"
        required = true
    end

    add_arg_group!(settings["track_single"], "optional arguments")
    @add_arg_table! settings["track_single"] begin
        "--dist"
        help = "Distance threholds to use for pairing floes"
        default = [200, 250, 300]
        arg_type = Int
        nargs = '+'

        "--dt-thresh"
        help = "Time thresholds to use for pairing floes"
        default = [30, 100, 1300]
        arg_type = Int
        nargs = '+'

        "--Sminimumarea"
        help = "Minimum area for small floes"
        arg_type = Float64
        default = 350

        "--Sarearatio"
        help = "Area ratio threshold for small floes"
        arg_type = Float64
        default = 0.18

        "--Smajaxisratio"
        help = "Major axis ratio threshold for small floes"
        arg_type = Float64
        default = 0.1

        "--Sminaxisratio"
        help = "Minor axis ratio threshold for small floes"
        arg_type = Float64
        default = 0.12

        "--Sconvexarearatio"
        help = "Convex area ratio threshold for small floes"
        arg_type = Float64
        default = 0.14

        "--Lminimumarea"
        help = "Minimum area for large floes"
        arg_type = Float64
        default = 1200

        "--Larearatio"
        help = "Area ratio threshold for large floes"
        arg_type = Float64
        default = 0.28

        "--Lmajaxisratio"
        help = "Major axis ratio threshold for large floes"
        arg_type = Float64
        default = 0.1

        "--Lminaxisratio"
        help = "Minor axis ratio threshold for large floes"
        arg_type = Float64
        default = 0.15

        "--Lconvexarearatio"
        help = "Convex area ratio threshold for large floes"
        arg_type = Float64
        default = 0.14

        # matchcorr computation
        "--mxrot"
        help = "Maximum rotation"
        arg_type = Int64
        default = 10

        "--psi"
        help = "Minimum psi-s correlation"
        arg_type = Float64
        default = 0.95

        "--sz"
        help = "Minimum side length of floe mask"
        arg_type = Int64
        default = 16

        "--comp"
        help = "Size comparability"
        arg_type = Float64
        default = 0.25

        "--mm"
        help = "Maximum registration mismatch"
        arg_type = Float64
        default = 0.22

        # Goodness of match
        "--corr"
        help = "Mininimun psi-s correlation"
        arg_type = Float64
        default = 0.68

        "--large_floe_area"
        help = "Large floe area mismatch threshold"
        arg_type = Float64
        default = 0.236

        "--small_floe_area"
        help = "Small floe area mismatch threshold"
        arg_type = Float64
        default = 0.18
    end
    return nothing
end

function mkclilandmask!(settings)
    args = [
        "input",
        Dict(:help => "Input image directory", :required => true),
        "output",
        Dict(:help => "Output image directory", :required => true),
    ]
    add_arg_table!(settings["landmask"], args...)
end

function mkclilandmask_single!(settings)
    @add_arg_table! settings["landmask_single"] begin
        "--input", "-i"
        help = "Input image"
        required = true

        "--output_non_dilated", "-o"
        help = "Output path for binarized landmask"
        required = true

        "--output_dilated", "-d"
        help = "Output path for dilated, binarized landmask"
        required = true
    end
    return nothing
end

function mkcli!(settings, common_args)
    d = Dict(
        "landmask" => mkclilandmask!,
        "landmask_single" => mkclilandmask_single!,
        "preprocess" => mkclipreprocess!,
        "preprocess_single" => mkclipreprocess_single!,
        "preprocess_tiling_single" => mkcli_preprocess_tiling_single!,
        "extractfeatures" => mkcliextract!,
        "extractfeatures_single" => mkcliextract_single!,
        "makeh5files" => mkclimakeh5!,
        "makeh5files_single" => mkclimakeh5_single!,
        "track" => mkclitrack!,
        "track_single" => mkclitrack_single!,
    )

    for t in keys(d)
        d[t](settings) # add arguments to settings
        add_arg_table!(settings[t], common_args...)
    end
    return nothing
end


function main()

    settings = ArgParseSettings(; autofix_names=true)

    @add_arg_table! settings begin
        "landmask"
        help = "Generate land mask images"
        action = :command

        "landmask_single"
        help = "Generate land mask images"
        action = :command

        "preprocess"
        help = "Label ice in a directory of truecolor & falsecolor images using full-image-based processing"
        action = :command

        "preprocess_single"
        help = "Label ice in a single set of truecolor & falsecolor images using full-image-based processing"
        action = :command

        "preprocess_tiling_single"
        help = "Label ice in a single set of truecolor & falsecolor images using tile-based processing"
        action = :command

        "extractfeatures"
        help = "Extract ice floe features from segmented floe image"
        action = :command

        "extractfeatures_single"
        help = "Extract ice floe features from a single segmented floe image"
        action = :command

        "makeh5files"
        help = "Make HDF5 files from extracted floe features"
        action = :command

        "makeh5files_single"
        help = "Make HDF5 files from extracted floe features"
        action = :command

        "track"
        help = "Pair ice floes in day k with ice floes in day k+1"
        action = :command

        "track_single"
        help = "Pair ice floes in day k with ice floes in day k+1"
        action = :command
    end

    command_common_args = []


    mkcli!(settings, command_common_args)

    parsed_args = parse_args(settings; as_symbols=true)

    command = parsed_args[:_COMMAND_]
    command_args = parsed_args[command]
    command_func = getfield(IFTPipeline, Symbol(command))

    @time command_func(; command_args...)

    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
