# IFTPipeline.jl

Command line interface for [IceFloeTracker.jl](https://github.com/WilhelmusLab/IceFloeTracker.jl)

## Testing

Run the tests in Julia:
```julia
julia> ]
(@v1.10) pkg> activate IFTPipeline.jl
(IFTPipeline) pkg> test
     Testing IFTPipeline
     ...
```

## Running the command line tools

Use the help for wrapper scripts to learn about available options in each wrapper function.
For example:
```
julia --project=IFTPipeline.jl ./src/cli.jl --help
```

## Debugging

Debug messages (from `@debug` macros in the code) can be activated for 
each command line task by calling Julia with the `JULIA_DEBUG` environment variable set.

To activate debug logging for the Ice Floe Tracker, call:
```bash
JULIA_DEBUG="Main,IFTPipeline,IceFloeTracker" julia --project=IFTPipeline.jl IFTPipeline.jl/src/cli.jl ...
```

## Troubleshooting

If you encouter errors with `PyCall` or `Conda`, follow the instructions in 
[../PythonSetupForIFTPipeline.jl](../PythonSetupForIFTPipeline.jl/) to reinitialize the Conda environment.