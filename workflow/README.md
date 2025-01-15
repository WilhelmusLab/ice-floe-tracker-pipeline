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

Add the following lines to the rose-suite.conf file with your space-track.org username and password:
```
SPACEUSER="your_email_address@example.com"
SPACEPSWD="yourpassword"
```

Don't commit these changes to the repo.
<!-- TODO: Insecure. Make this import from an environment file or the keychain. -->

#### Simple case: single target

Make a new configuration file with the region and time period you want to analyse. All the possible parameters are listed in [rose-suite.conf](./rose-suite.conf). You can see examples in [example](./example/). Command line usage examples are shown in [example-cylc-calls.sh](./example-cylc-calls.sh).

Run the pipeline by calling `cylc vip`, like this:
```bash
cylc vip . --set-file /path/to/your/configuration/file.conf --set PARAM="value" -n your-analysis-run-name
```

View progress of the pipeline by calling:
```bash
cylc tui
```
In the TUI you can view logs, and "trigger" (i.e., rerun) failed tasks.

Note that any parameters not specified in `/path/to/your/configuration/file.conf` 
nor specified using a `--set PARAM="value` argument
will default to the values in `rose-suite.conf`.


#### Advanced case: non-contiguous dates, multiple locations

The simplest way to generate runs of non-contiguous dates is to call `cylc vip` several times, e.g.:
```bash
cylc vip . --set-file example/hudson-bay.conf -n hudson-bay --run-name=may-2006 --initial-cycle-point=2006-05-04 --final-cycle-point=2006-05-06
cylc vip . --set-file example/hudson-bay.conf -n hudson-bay --run-name=july-2008 --initial-cycle-point=2008-07-13 --final-cycle-point=2008-07-15
```

The simplest way to process many different locations would be to make a location configuration file for each target location, and then to run a series of `cylc vip` commands as above.

You can also use this kind of approach to run the pipeline with different sets of parameters, e.g.:
```bash
for nclusters in 3 5 7; do 
  cylc vip . --set-file example/beaufort-sea-buckley-paper.conf -n beaufort-sea-cluster-test --run-name="${nclusters}-clusters" -s "ICEMASK_N_CLUSTERS=${nclusters}"
done
```

View the running commands by calling `cylc tui`.

#### Advanced use: case list

To loop through a list of cases, you might use a script like this:

```bash
name=sampled-examples

cylc stop ${name}/*;
cylc clean ${name} -y

datafile="example/all-cases.csv"
index_col="fullname"
for fullname in $(pipx run example/util/get_values.py "${datafile}" "${index_col}" --start 1 --stop 10);
do   
  cylc vip . -n ${name} --run-name=${fullname} $(pipx run example/util/template.py ${datafile} ${index_col} ${fullname}); 
done

cylc tui
```

The [`template.py`](./example/util/template.py) script provided doesn't currently have support for setting any other parameters, but could be extended if needed.

## Oscar

Contact the Wilhelmus Lab members for access to the pipeline environment on Brown University's High Performance Computing cluster "Oscar".

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