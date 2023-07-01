#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, ".")) # activate project environment

using ArgParse
using LoggingExtras
using IceFloeTracker
using IFTPipeline
using IFTPipeline: mkclipreprocess!, mkcliextract!, mkclitrack!, mkclilandmask!, mkcli!

"""
    setuplogger(option::Int64, path::String)

Setup logger for the ice floe tracker. If `option` is 0, log to file only. If `option` is 1, log to file and terminal.
"""
function setuplogger(option::Int64, command::Symbol)
    output = joinpath(@__DIR__, "..", "report")
    cmd = string(command)

    filelogger = FileLogger(joinpath(output, "$cmd-logfile.log")) # add command prefix to logfile name

    # filter out debug messages
    filtlogger = EarlyFilteredLogger(filelogger) do args
        r = Logging.Info <= args.level <= Logging.Warn && args._module === IFTPipeline
        return r
    end

    if option == 0
        return TeeLogger(filtlogger,
        )
    elseif option == 1
        return TeeLogger(
            global_logger(),
            filtlogger
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
        Dict(:help => "Show log on terminal; either 1 or 0", :required => false, :arg_type => Int,
            :default => 0, :range_tester => (x -> x == 0 || x == 1)
        )]

    mkcli!(settings, command_common_args)

    parsed_args = parse_args(args, settings; as_symbols=true)

    command = parsed_args[:_COMMAND_]
    command_args = parsed_args[command]
    command_func = getfield(IFTPipeline, Symbol(command))
    logoption = command_args[:log]

    # delete log option from command_args so it doesn't get passed to command_func
    delete!(command_args, :log)

    logger = setuplogger(logoption, command)

    with_logger(logger) do
        @time command_func(; command_args...)
    end
    return nothing
end

main(ARGS)
