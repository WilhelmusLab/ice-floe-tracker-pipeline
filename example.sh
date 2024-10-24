#!/usr/bin/env bash

datadir="example_data/beaufort_sea.20190320.250m.terra"
# datadir="example_data/ne_greenland.20220914.250m.aqua"
IFT="julia --project=IFTPipeline.jl/ IFTPipeline.jl/src/cli.jl"
FSDPROC="pipx run --editable --spec=/workspaces/ice-floe-tracker-workspace/ebseg fsdproc"
SOIT="pipx run --path ./lib/pass_time.py"

## Satellite Overpass Identification Tool (SOIT)
# . "${datadir}/.env"
# ${SOIT} --csvoutpath ${datadir}/soit.csv \
#     --startdate ${START} --enddate ${END} \
#     --centroid-lat ${CENTROID_LAT} --centroid-lon ${CENTROID_LON} \
#     --SPACEUSER ${SPACEUSER} --SPACEPSWD ${SPACEPSWD} --satellite ${SATELLITE}


## Preprocess
### Buckley

# workdir="${datadir}/segmented_floes.tiff.work/"
# mkdir -p "${workdir}"
# ${FSDPROC} process ${datadir}/truecolor.tiff  ${datadir}/cloud.tiff ${datadir}/landmask.tiff ${workdir}
# cp ${workdir}/final.tif ${datadir}/segmented_floes.tiff
# cp ${workdir}/props.csv ${datadir}/segmented_floes.props.csv

## Preprocess 
### Original

# ${IFT} preprocess_single --truecolor ${datadir}/truecolor.tiff --falsecolor ${datadir}/falsecolor.tiff --landmask ${datadir}/landmask.binarized.tiff --landmask-dilated ${datadir}/landmask.binarized.dilated.tiff --output ${datadir}/segmented_floes.tiff
# ${IFT} extractfeatures_single --input ${datadir}/segmented_floes.tiff --output ${datadir}/segmented_floes.props.csv --minarea 1 --maxarea 100000

## Track
# Pairs
#${IFT} track_single --imgs ${datadir}/segmented_floes.tiff ${datadir}/segmented_floes.tiff --props ${datadir}/segmented_floes.props.csv ${datadir}/segmented_floes.props.csv --latlon ${datadir}/truecolor.tiff --passtimes "2021-05-26T21:00" "2021-05-27T21:00" --output ${datadir}/tracked_floes.pairs.csv

# Triples
#${IFT} track_single --imgs ${datadir}/segmented_floes.tiff ${datadir}/segmented_floes.tiff ${datadir}/segmented_floes.tiff --props ${datadir}/segmented_floes.props.csv ${datadir}/segmented_floes.props.csv ${datadir}/segmented_floes.props.csv --latlon ${datadir}/truecolor.tiff --passtimes "2021-05-26T21:00" "2021-05-27T21:00" "2021-05-28T21:00" --output ${datadir}/tracked_floes.triples.csv

# h5files
${IFT} makeh5files_single --passtime "2021-05-26T21:00" --truecolor ${datadir}/truecolor.tiff --falsecolor ${datadir}/falsecolor.tiff --labeled ${datadir}/segmented_floes.tiff --props ${datadir}/segmented_floes.props.csv --output ${datadir}/results.h5