"""
IFTPipeline

This module contains wrapper functions for IceFloeTracker.jl pipeline.
"""
module IFTPipeline
using ArgParse
using LoggingExtras
using IceFloeTracker
using IceFloeTracker: DataFrames, Dates, @dateformat_str, DataFrame, nrow, rename!, Not, select!, Date, Time, DateTime
using IceFloeTracker: RGB, Gray, load, float64, imsharpen, getlatlon
using Folds
using HDF5
using TOML: parsefile
using Pkg
include("cli-config.jl")
include("soit-parser.jl")
include("landmask.jl")
include("preprocess.jl")
include("feature-extraction.jl")
include("tracker.jl")
include("h5.jl")

const iftversion = []
function __init__()
    function getiftversion()
        deps = Pkg.dependencies()
        iftversion = []
        for (_, dep) in deps
            dep.is_direct_dep || continue
            dep.version === nothing && continue
            dep.name != "IceFloeTracker" && continue
            push!(iftversion, dep.version)
            break
        end

        # For CI tests where IceFloeTracker is not a dependency
        try
            ift = iftversion[]
        catch
            return "unknown"
        end

        ift = iftversion[]
        maj = Int(ift.major)
        min = Int(ift.minor)
        patch = Int(ift.patch)
        return "v$maj.$min.$patch"
    end

    push!(iftversion, getiftversion())
    return nothing
end

export cache_vector, sharpen,
    sharpen_gray,
    preprocess,
    cloudmask,
    extractfeatures,
    get_ice_labels,
    label_components,
    load_imgs,
    load_truecolor_imgs,
    load_reflectance_imgs,
    load_cloudmask,
    disc_ice_water,
    landmask,
    track,
    mkclipreprocess!,
    mkcliextract!,
    mkclitrack!,
    mkfilenames,
    makeh5files,
    getlatlon,
    iftversion

export IceFloeTracker
end
