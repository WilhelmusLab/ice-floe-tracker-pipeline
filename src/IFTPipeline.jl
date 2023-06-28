"""
IFTPipeline

This module contains wrapper functions for IceFloeTracker.jl pipeline.
"""
module IFTPipeline
using ArgParse
using LoggingExtras
using IceFloeTracker
using IceFloeTracker: Folds, RGB, Gray, load, float64, imsharpen
using Dates
using DataFrames
using TOML: parsefile
using PyCall
include("cli-config.jl")
include("soit-parser.jl")
include("landmask.jl")
include("preprocess.jl")
include("feature-extraction.jl")
include("tracker.jl")

const np = PyNULL()
const pyproj = PyNULL()
const rasterio = PyNULL()

function __init__()
    copy!(np, pyimport_conda("numpy", "numpy=1.25.0"))
    copy!(pyproj, pyimport_conda("pyproj", "pyproj=3.6.0"))
    copy!(rasterio, pyimport_conda("rasterio", "rasterio=1.3.7"))
end

export cache_vector, sharpen,
    sharpen_gray,
    preprocess,
    cloudmask,
    extractfeatures,
    get_ice_labels,
    load_imgs,
    load_truecolor_imgs,
    load_reflectance_imgs,
    load_cloudmask,
    disc_ice_water,
    landmask,
    track,
    mkclipreprocess!,
    mkcliextract!,
    mkclitrack!
end
