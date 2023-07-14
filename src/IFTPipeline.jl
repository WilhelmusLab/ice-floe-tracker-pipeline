"""
IFTPipeline

This module contains wrapper functions for IceFloeTracker.jl pipeline.
"""
module IFTPipeline
using ArgParse
using LoggingExtras
using IceFloeTracker
using IceFloeTracker: DataFrames, Dates, @dateformat_str, DataFrame, nrow, rename!, Not, select!, Date, Time, DateTime
using IceFloeTracker: Folds, RGB, Gray, load, float64, imsharpen
using TOML: parsefile
using PyCall
include("cli-config.jl")
include("soit-parser.jl")
include("landmask.jl")
include("preprocess.jl")
include("feature-extraction.jl")
include("tracker.jl")

"""
    __init__()

Initialize the Python dependencies for the pipeline. This function is called automatically when the module is loaded for the first time. See the help for `__init__` for more information.
"""
function __init__()
    pyimport_conda("numpy", "numpy=1.25.0")
    pyimport_conda("pyproj", "pyproj=3.6.0")
    pyimport_conda("rasterio", "rasterio=1.3.7")
    pyimport_conda("requests", "requests=2.31.0")
    pyimport_conda("skyfield", "skyfield=1.45.0")
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
<<<<<<< HEAD
    mkclitrack!,
    mkfilenames
=======
    mkclitrack!
    
export IceFloeTracker

>>>>>>> main
end
