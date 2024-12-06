[![Build Status](https://github.com/WilhelmusLab/ice-floe-tracker-pipeline/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/WilhelmusLab/ice-floe-tracker-pipeline/actions/workflows/test.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/WilhelmusLab/ice-floe-tracker-pipeline/branch/main/graph/badge.svg)](https://codecov.io/gh/WilhelmusLab/ice-floe-tracker-pipeline)
# Ice Floe Tracker Pipeline

This repository contains the processing pipeline for IceFloeTracker.jl.

The [workflow](./workflow/) directory includes instructions for running the workflow as a whole, in Cylc, and may be the only directory you need to interact with.

The other directories include utilities and are intended for developers:
- [PythonSetupForIFTPipeline.jl](./PythonSetupForIFTPipeline.jl/) – script to initialize a working Conda environment, in Julia
- [IFTPipeline.jl](./IFTPipeline.jl/) – command line interface to the ice floe tracker by Lopez ([IceFloeTracker.jl](https://github.com/WilhelmusLab/IceFloeTracker.jl)), in Julia
- [label-colorizer](./label-colorizer/) – command line tool to apply random colors to integer GEOTiff images, in Python 
- [satellite-overpass-identification-tool](./satellite-overpass-identification-tool/) – command line tool to get satellite overpass times from the Aqua and Terra satellites, in Python
- [test](./test/) – command line scripts to test all the command line tool functionality

The related repository [ebseg](https://github.com/WilhelmusLab/ebseg/) is also used, and provides an alternative preprocessing pipeline by Buckley.

See the [Development Guide](./DEVELOPMENT.md) for instructions on setting up your environment.