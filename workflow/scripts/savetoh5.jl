#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, "../..")) # activate project environment

using DataFrames
using Dates
using HDF5
using IFTPipeline
using PyCall
using Serialization
using ArgParse: @add_arg_table, ArgParseSettings, parse_args

include("h5.jl")

function parse_commandline()
    settings = ArgParseSettings()

    @add_arg_table settings begin
        "--pathtosampleimg", "-p"
        help = "Path to a sample image with coordinate reference system (CRS) and latitude and longitude coordinates of image pixels"
        arg_type = String

        "--resdir", "-r"
        help = "Path to the directory containing the results of the IceFloeTracker pipeline"
        arg_type = String
    end

    return parse_args(settings; as_symbols=true)
end

function main()
    # Parse command line arguments
    args = (; parse_commandline()...)
    for (k, v) in zip(keys(args), args)
        @info "$(lpad(k, 8)) =>  $v"
    end

    pathtosampleimg = args.pathtosampleimg
    resdir = args.resdir

    makeh5file(pathtosampleimg, resdir)
    pth = joinpath(resdir, "hdf5-files")
    files = readdir(pth)
    @info "$(length(files)) h5-files written to $(pth)"
    [println("\t\t$(file)") for file in files]
    @info "Run completed successfully"
end

main()
