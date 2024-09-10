#!/usr/bin/env julia

using ArgParse
using LoggingExtras
using IceFloeTracker
using IFTPipeline
using IFTPipeline: mkclipreprocess!, mkcliextract!, mkclitrack!, mkclilandmask!, mkcli!
using Serialization


"""
    setuplogger(option::Int64, path::String)

Setup logger for the ice floe tracker. If `output` a directory path, log to the directory in addition to STDOUT and STDERR.
"""
function setuplogger(command::Symbol, output::Union{String,Nothing}=nothing)
    
    if isnothing(output)
        return TeeLogger(
            global_logger()
            )
    else
        cmd = string(command)
        filelogger = FileLogger(joinpath(output, "$cmd-logfile.log")) # add command prefix to logfile name
    
        # filter out debug messages
        filtlogger = EarlyFilteredLogger(filelogger) do args
            r = Logging.Info <= args.level <= Logging.Warn && args._module === IFTPipeline
            return r
        end

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
        help = "Preprocess truecolor/falsecolor images"
        action = :command

        "extractfeatures"
        help = "Extract ice floe features from segmented floe image"
        action = :command

        "makeh5files"
        help = "Make HDF5 files from extracted floe features"
        action = :command

        "track"
        help = "Pair ice floes in day k with ice floes in day k+1"
        action = :command
    end

    command_common_args = [
        "--log",
        Dict(:help => "Path for logging outputs", :required => false, :arg_type => String)
        ]

    mkcli!(settings, command_common_args)

    parsed_args = parse_args(args, settings; as_symbols=true)

    command = parsed_args[:_COMMAND_]
    command_args = parsed_args[command]
    command_func = getfield(IFTPipeline, Symbol(command))
    log_path = command_args[:log]

    # delete log option from command_args so it doesn't get passed to command_func
    delete!(command_args, :log)

    logger = setuplogger(command, log_path)

    with_logger(logger) do
        @time command_func(; command_args...)
    end
    return nothing
end

main(ARGS)
