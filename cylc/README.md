# Oscar Setup

## Prerequisites

`pipx` is available in the `../runtime/venv` virtual environment. Load it using:

```bash
module load python/3.11.0s-ixrhc3q
. ../runtime/venv/bin/activate
```

Install `cylc-rose` using:

```bash
pipx install cylc-rose --include-deps  # this will install cylc and rose
```

## Slurm

Update your `~/.cylc/flow/global.cylc` file to include the following lines:
```
[platforms]
    [[localhost]]
        job runner = slurm
```

This will ensure that jobs from `cylc` are scheduled using `Slurm`.

