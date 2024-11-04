# Satellite Overpass Identification Tool

The [Satellite Overpass Identification Tool](https://zenodo.org/record/6475619#.ZBhat-zMJUe) is called to generate a list of satellite times for both Aqua and Terra in the area of interest.

## Run the code

You can run the local version of the code by calling
```bash
pipx run -e satellite_overpass_identification_tool.py 
```

You can run the code anywhere by calling:
```bash
# TODO: Remove branch specifier once merged
pipx run --spec "git+https://github.com/wilhelmuslab/ice-floe-tracker-pipeline@jghrefactor/C-update-soit-to-use-pipx#egg=satellite-overpass-identification-tool&subdirectory=satellite-overpass-identification-tool" soit
```

