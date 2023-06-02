"""
IFTPipeline

This module contains wrapper functions for IceFloeTracker.jl pipeline.
"""
module IFTPipeline
using ArgParse
using IceFloeTracker
using IceFloeTracker: Folds, RGB, Gray, load, float64, imsharpen
using Dates
using DataFrames
using TOML: parsefile
include("cli-config.jl")
include("soit-parser.jl")
include("landmask.jl")
include("preprocess.jl")
include("feature-extraction.jl")
include("tracker.jl")
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
