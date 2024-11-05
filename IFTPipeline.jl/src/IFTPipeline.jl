"""
IFTPipeline

This module contains wrapper functions for IceFloeTracker.jl pipeline.
"""
module IFTPipeline
using ArgParse
using LoggingExtras
using IceFloeTracker
using IceFloeTracker: DataFrames, Dates, @dateformat_str, DataFrame, nrow, rename!, Not, select!, Date, Time, DateTime
using IceFloeTracker: RGB, Gray, load, float64, imsharpen, getlatlon, pairfloes
using Folds
using HDF5
using TOML: parsefile
using Pkg
using FileIO
using Images
using CSV
using ImageSegmentation

include("cli.jl")
include("soit-parser.jl")
include("landmask.jl")
include("preprocess.jl")
include("feature-extraction.jl")
include("tracker.jl")
include("h5.jl")

export cache_vector, sharpen,
    sharpen_gray,
    preprocess,
    preprocess_single,
    cloudmask,
    extractfeatures,
    get_ice_labels,
    label_components,
    load_imgs,
    load_truecolor_imgs,
    load_falsecolor_imgs,
    load_cloudmask,
    disc_ice_water,
    landmask,
    landmask_single,
    track,
    mkclipreprocess!,
    mkclipreprocess_single!,
    mkcliextract!,
    mkclitrack!,
    mkfilenames,
    makeh5files,
    getlatlon

export IceFloeTracker
end
