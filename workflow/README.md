# Workflow

This directory includes tools to run the ice floe tracker analysis on a batch of satellite images.

## General Use

### Prerequisites

You will need the following installed on your computer:
- [`pipx`](https://pipx.pypa.io/stable/)
- [`cylc`](https://cylc.github.io/) 
  - the `cylc-rose` plugin
  - [`global.cylc`](https://cylc.github.io/cylc-doc/stable/html/reference/config/global.html#global.cylc) file, making any modifications you might want.
- [`docker`](https://docs.docker.com/)

You will also need a username and account on [space-track.org](https://space-track.org)

### Running the pipeline

Make a new configuration file with the region and time period you want to analyse. All the possible parameters are listed in [rose-suite.conf](./rose-suite.conf). You can see examples in [example](./example/). 

Add the following lines to the rose-suite.conf file with your space-track.org username and password:
```
SPACEUSER="your_email_address@example.com"
SPACEPSWD="yourpassword"
```

Don't commit these changes to the repo.
<!-- TODO: Insecure. Make this import from an environment file or the keychain. -->


Run the pipeline by calling:
```bash
cylc vip . --set-file /path/to/your/configuration/file.conf -n your-analysis-run-name
```

Command line usage examples are shown in [example-cylc-calls.sh](./example-cylc-calls.sh).

View the running commands by calling `cylc tui`.

## Oscar

Contact the Wilhelmus Lab members for access to the pipeline environment on Oscar, Brown University's High Performance Computing cluster.

## Prerequisites

`pipx`, `cylc` and `cylc-rose` are available in the `../runtime/venv` virtual environment. Load it using:

```bash
module load python/3.11.0s-ixrhc3q
. ../runtime/venv/bin/activate
```

Update your `~/.cylc/flow/global.cylc` file to include the following lines to use the SLURM scheduler:
```
[platforms]
    [[localhost]]
        job runner = slurm
```

This will ensure that jobs from `cylc` are scheduled using `Slurm`.

Oscar uses Apptainer rather than Docker, so include the line `IFT_INSTALL="Apptainer"` or `IFT_INSTALL="ApptainerLocal"` in your configuration file.

## Development Use

If you're working on the workflow steps, you may wish to use a local version of the command line tools `IceFloeTracker.jl`, `fsdproc`, `satellite-overpass-identification-tool` or `label-colorizer`. 

To enable those, in `rose-suite.conf`:
- Set the `_INSTALL` for that tool to `"Inject"`
- Set the `_COMMAND` for that tool to the full path to the local installation

For example, to use a local version of `IceFloeTracker.jl`, already fully instantiated at `/path/to/IceFloeTracker.jl`, you would use the following settings:
```
IFT_INSTALL="Inject"
IFT_COMMAND="julia --project=/path/to/IceFloeTracker.jl /path/to/IceFloeTracker.jl/src/cli.jl"
```

To use a local version of `satellite-overpass-identification-tool` installed into the virtual environment `/path/to/venv/` , you would use the following settings:
```
PASS_TIME_INSTALL="Inject"
PASS_TIME_COMMAND="/path/to/venv/bin/soit"
```

To use a local version of `satellite-overpass-identification-tool` without a pre-existing virtual environment, you would use the following settings:
```
PASS_TIME_INSTALL="Inject"
PASS_TIME_COMMAND="pipx run --editable --spec /path/to/satellite-overpass-identification-tool/ soit"
```

To use a specific Dockerized version of the Ice Floe Tracker Pipeline CLI tagged `brownccv/icefloetracker-julia:v3.0.0-dev`, you would use the following settings:
```
IFT_INSTALL="Inject"
IFT_COMMAND="docker run -v `pwd`:/app -w /app brownccv/icefloetracker-julia:v3.0.0-dev"
```

> When you run `IFT_COMMAND` in `/some/local/directory/` containing the data you want to process, the fragment ``-v `pwd`:/app`` mounts `/some/local/directory` to the `/app` directory of the container. `-w /app` sets the working directory within the container to `/app`. Together, these allow the container to interact with the data to be processed.