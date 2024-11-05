#!/usr/bin/env bash

# Set variables with the script names we're going to use. 
# If these are set as environment variables outside, then the outside version will be used.
# This might be useful if you're trying to test a Docker container – 
# you can replace IFT with the version from your docker container.
# The `:` at the start is deep bash magic. 
# Refs:
# - https://stackoverflow.com/a/28085062/24937841 and 
# - https://unix.stackexchange.com/a/31712
: "${IFT:=julia --project=`pwd`/../IFTPipeline.jl `pwd`/../IFTPipeline.jl/src/cli.jl}"
echo "IFT=${IFT}"

# Data target
TEMPDIR=$(mktemp -d -p .)
: "${DATA_TARGET:=$TEMPDIR}"
echo "DATA_TARGET=${DATA_TARGET}"

# Initialize data directory
: "${DATA_SOURCE:=./input_data}"
echo "DATA_SOURCE=${DATA_SOURCE}"

cp -r ${DATA_SOURCE}/* ${DATA_TARGET}/
cd ${DATA_TARGET}
echo "in ${DATA_TARGET}"

SAMPLEIMG=20220914.terra.truecolor.250m.tiff

# Set up debug messages
export JULIA_DEBUG="Main,IFTPipeline,IceFloeTracker" 

# Run the processing (single files)
LANDMASK=landmask.tiff
LANDMASK_NON_DILATED=landmask.non-dilated.tiff
LANDMASK_DILATED=landmask.dilated.tiff

${IFT} landmask_single -i ${LANDMASK} -o ${LANDMASK_NON_DILATED} -d ${LANDMASK_DILATED}

for satellite in "aqua" "terra"
do
    TRUECOLOR=20220914.${satellite}.truecolor.250m.tiff
    FALSECOLOR=20220914.${satellite}.falsecolor.250m.tiff
    SEGMENTED=20220914.${satellite}.segmented.250m.tiff
    FLOEPROPERTIES=20220914.${satellite}.segmented.250m.props.csv
    HDF5FILE=20220914.${satellite}.h5
    ${IFT} preprocess_single --truecolor ${TRUECOLOR} --falsecolor ${FALSECOLOR} --landmask ${LANDMASK_NON_DILATED} --landmask-dilated ${LANDMASK_DILATED} --output ${SEGMENTED}
    ${IFT} extractfeatures_single --input ${SEGMENTED} --output ${FLOEPROPERTIES}
    ${IFT} makeh5files_single --passtime "2022-09-14T12:00:00" --truecolor ${TRUECOLOR} --falsecolor ${FALSECOLOR} --labeled ${SEGMENTED} --props ${FLOEPROPERTIES} --output ${HDF5FILE}
done

${IFT} track_single --imgs 20220914.{aqua,terra}.segmented.250m.tiff --props 20220914.{aqua,terra}.segmented.250m.props.csv --latlon ${TRUECOLOR} --passtimes "2022-09-14T12:00:00" "2022-09-15T12:00:00" --output paired-floes.csv



# Run the processing (batch)
${IFT} landmask ${DATA_TARGET} ${DATA_TARGET}
${IFT} preprocess -t ${DATA_TARGET} -r ${DATA_TARGET} -l ${DATA_TARGET} -p ${DATA_TARGET} -o ${DATA_TARGET}
${IFT} extractfeatures -i ${DATA_TARGET} -o ${DATA_TARGET}
${IFT} track --imgs ${DATA_TARGET} --props ${DATA_TARGET} --passtimes ${DATA_TARGET} --latlon ${SAMPLEIMG} -o ${DATA_TARGET}
${IFT} makeh5files --pathtosampleimg ${SAMPLEIMG} --resdir ${DATA_TARGET}

