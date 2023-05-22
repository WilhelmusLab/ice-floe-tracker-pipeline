"""
IFTPipeline

This module contains wrapper functions for IceFloeTracker.jl pipeline.
"""
module IFTPipeline
using ArgParse
using IceFloeTracker
using IceFloeTracker: Folds, DataFrame, RGB, Gray, load, float64, imsharpen
using TOML: parsefile
include("landmask.jl")
include("preprocess.jl")
include("feature-extraction.jl")
include("tracker.jl")
export sharpen,
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
    track
end