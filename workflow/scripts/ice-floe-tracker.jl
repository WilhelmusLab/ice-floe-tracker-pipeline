#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, "../..")) # activate project environment

using ArgParse
using LoggingExtras
using IceFloeTracker
using IFTPipeline
using IFTPipeline: mkclipreprocess!, mkcliextract!, mkclitrack!, mkclilandmask!, mkcli!

"""
    setuplogger(option::Int64, path::String)

Setup logger for the ice floe tracker. If `option` is 0, log to file only. If `option` is 1, log to file and terminal.
"""
function setuplogger(option::Int64, path::String)
    if option == 0
        return TeeLogger(
            FileLogger(joinpath(path, "logfile.log"))
        )
    elseif option == 1
        return TeeLogger(
            global_logger(),
            FileLogger(joinpath(path, "logfile.log"))
        )
    end
end

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

        "track"
        help = "Pair ice floes in day k with ice floes in day k+1"
        action = :command
    end

    command_common_args = [
        "--log",
        Dict(:help => "Show log on terminal", :required => false, :arg_type => Int,
            :default => 0,
        )]

    mkcli!(settings, command_common_args)

    parsed_args = parse_args(args, settings; as_symbols=true)

    command = parsed_args[:_COMMAND_]
    command_args = parsed_args[command]
    command_func = getfield(IFTPipeline, Symbol(command))

    logoption = command_args[command][:log]
    output = command_args[command][:output]
    logger = setuplogger(logoption, output)

    with_logger(logger) do
        command_func(; command_args...)
    end
    return nothing
end

main(ARGS)
