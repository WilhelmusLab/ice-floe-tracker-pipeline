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

### Running the pipeline

Make a new configuration file with the region and time period you want to analyse. All the possible parameters are listed in [rose-suite.conf](./rose-suite.conf). You can see examples in [example](./example/). 

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

Update your `~/.cylc/flow/global.cylc` file to include the following lines:
```
[platforms]
    [[localhost]]
        job runner = slurm
```

This will ensure that jobs from `cylc` are scheduled using `Slurm`.

Oscar uses Apptainer rather than Docker, so include the line `IFT_INSTALL="Apptainer"` or `IFT_INSTALL="ApptainerLocal"` in your configuration file.