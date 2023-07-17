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
using HDF5
using TOML: parsefile
using Conda
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
    Conda.add("numpy==1.25.0", channel="conda-forge")
    Conda.add("pyproj==3.6.0", channel="conda-forge")
    Conda.add("rasterio==1.3.7", channel="conda-forge")
    Conda.add("requests==2.31.0", channel="conda-forge")
    Conda.add("skyfield==1.45.0", channel="conda-forge")
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
    HDF5,
    h5open,
    attrs,
    create_group

export IceFloeTracker
end
