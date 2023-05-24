function mkclipreprocess!(settings)
    @add_arg_table! settings["preprocess"] begin
        "--truedir", "-t"
        help = "Truecolor image directory"
        required = true

        "--refdir", "-r"
        help = "Reflectance image directory"
        required = true

        "--lmdir", "-l"
        help = "Land mask image directory"
        required = true

        "--output", "-o"
        help = "Output directory"
        required = true
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
        default = "300"

        "--maxarea"
        help = "Maximum area (in pixels) of ice floes to extract"
        default = "90000"

        "--features", "-f"
        help = """Features to extract. Format: "feature1 feature2". For an extensive list of extractable features see https://scikit-image.org/docs/stable/api/skimage.measure.html#skimage.measure.regionprops:~:text=The%20following%20properties%20can%20be%20accessed%20as%20attributes%20or%20keys"""
        default = "centroid area major_axis_length minor_axis_length convex_area bbox orientation"
    end
    return nothing
end

"""
    mkclitrack!(settings)

Set up command line interface for the `track` command.
"""
function mkclitrack!(settings)
    @add_arg_table! settings begin
        "track"
        help = "Pair ice floes in day k with ice floes in day k+1"
        action = :command
    end

    add_arg_group!(settings["track"], "arguments")
    @add_arg_table! settings["track"] begin
        "--imgs"
        help = "Path to object with segmented images"
        required = true

        "--props"
        help = "Path to object with extracted features"
        required = true

        "--deltat"
        help = "Path to object with time deltas between consecutive images"
        required = true

        "--output", "-o"
        help = "Output directory"
        required = true
    end

    add_arg_group!(settings["track"], "optional arguments")
    @add_arg_table! settings["track"] begin
        "--params"
        help = "Path to TOML file with algorithm parameters"

        "--area"
        help = "Area thresholds to use for pairing floes"
        arg_type = Int64
        default = 1200

        "--dist"
        help = "Distance threholds to use for pairing floes"
        default = "15 30 120"

        "--dt-thresh"
        help = "Time thresholds to use for pairing floes"
        default = "30 100 1300"

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

        "--area2"
        help = "Large floe area mismatch threshold"
        arg_type = Float64
        default = 0.236

        "--area3"
        help = "Small floe area mismatch threshold"
        arg_type = Float64
        default = 0.18
    end
    return nothing
end