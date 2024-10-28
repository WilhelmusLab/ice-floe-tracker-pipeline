# Python Setup for IFTPipeline.jl

This project is designed to initialize the Python Environment for IFTPipeline.jl.
It should be used once before IFTPipeline.jl is instantiated.
It will:

- Create a new `base` Conda environment which PyCall will use,
- Install dependencies to that environment,
- Rebuild PyCall using the updated environment.

Since the `base` environment is shared between all PyCall instances by default, it only needs to be run if the Conda environment is:
- missing – as in a new installation, or 
- broken – new incompatible dependencies have been added.

The goal is to remove the need for this subpackage at some point in future. 

## User Guide

To use, run:
```bash
julia --project="PythonSetupForIFTPipeline.jl" PythonSetupForIFTPipeline.jl/setup.jl
```

> If this fails, try removing the existing Conda installation for Julia:
> ```bash
> rm -r ~/.julia/conda/
> ```
> ... and then retry.