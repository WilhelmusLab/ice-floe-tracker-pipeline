#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, "../..")) # activate project environment

using ArgParse
using IceFloeTracker
using IFTPipeline

function main(args)
    settings = ArgParseSettings(; autofix_names=true)

    @add_arg_table! settings begin
        "landmask"
        help = "Generate land mask images"
        action = :command

        "preprocess"
        help = "Preprocess truecolor/reflectance images"
        action = :command

        "extractfeatures"
        help = "Extract ice floe features from segmented floe image"
        action = :command
    end

    mkclipreprocess!(settings)
    mkcliextract!(settings)
    mkclitrack!(settings)

    landmask_cloudmask_args = [
        "--input",
        Dict(:help => "Input image directory", :required => true),
        "--output",
        Dict(:help => "Output image directory", :required => true),
    ]

    add_arg_table!(settings["landmask"], landmask_cloudmask_args...)

    parsed_args = parse_args(args, settings; as_symbols=true)

    command = parsed_args[:_COMMAND_]
    command_args = parsed_args[command]
    command_func = getfield(IFTPipeline, Symbol(command))
    @time command_func(; command_args...)
    return nothing
end

main(ARGS)
