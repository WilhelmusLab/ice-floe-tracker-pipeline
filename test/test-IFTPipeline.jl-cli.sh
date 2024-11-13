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

: "${FSDPROC:="pipx run --spec /workspaces/ice-floe-tracker-workspace/ebseg fsdproc --debug"}"
echo "FSDPROC=${FSDPROC}"


# Data target
TEMPDIR=$(mktemp -d -p .)
: "${DATA_TARGET:=$TEMPDIR}"
echo "DATA_TARGET=${DATA_TARGET}"

# Initialize data directory
: "${DATA_SOURCE:=./input_data}"
echo "DATA_SOURCE=${DATA_SOURCE}"

cp -r ${DATA_SOURCE}/* ${DATA_TARGET}/
echo "in $(pwd)"

SAMPLEIMG=20220914.terra.truecolor.250m.tiff

# Set up debug messages
export JULIA_DEBUG="Main,IFTPipeline,IceFloeTracker" 

# Run the processing (single files)
LANDMASK=${DATA_TARGET}/landmask.tiff
LANDMASK_NON_DILATED=${DATA_TARGET}/landmask.non-dilated.tiff
LANDMASK_DILATED=${DATA_TARGET}/landmask.dilated.tiff

# ${IFT} landmask_single -i ${LANDMASK} -o ${LANDMASK_NON_DILATED} -d ${LANDMASK_DILATED}

# for satellite in "aqua" "terra"
# do
#     TRUECOLOR=${DATA_TARGET}/20220914.${satellite}.truecolor.250m.tiff
#     FALSECOLOR=${DATA_TARGET}/20220914.${satellite}.falsecolor.250m.tiff
#     LABELED=${DATA_TARGET}/20220914.${satellite}.labeled.250m.tiff
#     FLOEPROPERTIES=${DATA_TARGET}/20220914.${satellite}.labeled.250m.props.csv
#     HDF5FILE=${DATA_TARGET}/20220914.${satellite}.h5
    
#     ${IFT} preprocess_single \
#         --truecolor ${TRUECOLOR} \
#         --falsecolor ${FALSECOLOR} \
#         --landmask ${LANDMASK_NON_DILATED} \
#         --landmask-dilated ${LANDMASK_DILATED} \
#         --output ${LABELED}
    
#     ${IFT} extractfeatures_single \
#         --input ${LABELED} \
#         --output ${FLOEPROPERTIES}
    
#     ${IFT} makeh5files_single \
#         --passtime "2022-09-14T12:00:00" \
#         --truecolor ${TRUECOLOR} \
#         --falsecolor ${FALSECOLOR} \
#         --labeled ${LABELED} \
#         --props ${FLOEPROPERTIES} \
#         --output ${HDF5FILE}
# done

# ${IFT} track_single \
#     --imgs ${DATA_TARGET}/20220914.{aqua,terra}.labeled.250m.tiff \
#     --props ${DATA_TARGET}/20220914.{aqua,terra}.labeled.250m.props.csv \
#     --latlon ${TRUECOLOR} \
#     --passtimes "2022-09-14T12:00:00" "2022-09-15T12:00:00" \
#     --output ${DATA_TARGET}/paired-floes.csv

# # Run the processing (batch)
# ${IFT} landmask ${DATA_TARGET} ${DATA_TARGET}
# ${IFT} preprocess -t ${DATA_TARGET} -r ${DATA_TARGET} -l ${DATA_TARGET} -p ${DATA_TARGET} -o ${DATA_TARGET}
# ${IFT} extractfeatures -i ${DATA_TARGET} -o ${DATA_TARGET}
# ${IFT} track --imgs ${DATA_TARGET} --props ${DATA_TARGET} --passtimes ${DATA_TARGET} --latlon ${SAMPLEIMG} -o ${DATA_TARGET}
# ${IFT} makeh5files --pathtosampleimg ${SAMPLEIMG} --resdir ${DATA_TARGET}

# Run the processing (Buckley)
for satellite in "aqua" "terra"
do
    TRUECOLOR=${DATA_TARGET}/20220914.${satellite}.truecolor.250m.tiff
    FALSECOLOR=${DATA_TARGET}/20220914.${satellite}.falsecolor.250m.tiff
    CLOUD=${DATA_TARGET}/20220914.${satellite}.cloud.250m.tiff
    LABELED_DIR=${DATA_TARGET}/20220914.${satellite}.labeled-buckley.250m.tiff.work
    LABELED=${DATA_TARGET}/20220914.${satellite}.labeled-buckley.250m.tiff
    FLOEPROPERTIES=${DATA_TARGET}/20220914.${satellite}.labeled-buckley.250m.props.csv
    HDF5FILE=${DATA_TARGET}/20220914.${satellite}.buckley.h5
    
    ${FSDPROC} process ${TRUECOLOR} ${CLOUD} ${LANDMASK} ${LABELED_DIR}
    cp ${LABELED_DIR}/final.tif ${LABELED}
    cp ${LABELED_DIR}/props.csv ${FLOEPROPERTIES}
    
    ${IFT} makeh5files_single \
        --passtime "2022-09-14T12:00:00" \
        --truecolor ${TRUECOLOR} \
        --falsecolor ${FALSECOLOR} \
        --labeled ${LABELED} \
        --props ${FLOEPROPERTIES} \
        --output ${HDF5FILE}
done

${IFT} track_single \
    --imgs ${DATA_TARGET}/20220914.{aqua,terra}.labeled-buckley.250m.tiff \
    --props ${DATA_TARGET}/20220914.{aqua,terra}.labeled-buckley.250m.props.csv \
    --latlon ${TRUECOLOR} \
    --passtimes "2022-09-14T12:00:00" "2022-09-15T12:00:00" \
    --output ${DATA_TARGET}/paired-floes-buckley.csv