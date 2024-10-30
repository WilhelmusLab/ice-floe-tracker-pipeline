#!/usr/bin/env bash

# Set variables with the script names we're going to use. 
# If these are set as environment variables outside, then the outside version will be used.
# This might be useful if you're trying to test a Docker container – 
# you can replace IFT with the version from your docker container.
# The `:` at the start is deep bash magic. 
# Refs:
# - https://stackoverflow.com/a/28085062/24937841 and 
# - https://unix.stackexchange.com/a/31712
: "${IFT:=julia --project=../IFTPipeline.jl ../IFTPipeline.jl/src/cli.jl}"
echo "IFT=${IFT}"

# Data target
TEMPDIR=$(mktemp -d)
: "${DATA_TARGET:=$TEMPDIR}"
echo "DATA_TARGET=${DATA_TARGET}"

# Initialize data directory
: "${DATA_SOURCE:=../IFTPipeline.jl/test/test_inputs/input_pipeline}"
echo "DATA_SOURCE=${DATA_SOURCE}"
ls /
ls /mnt
cp ${DATA_SOURCE}/20220914.{terra,aqua}.{true,false}color.250m.tiff ${DATA_TARGET}
cp ${DATA_SOURCE}/landmask.tiff ${DATA_TARGET}
cp ${DATA_SOURCE}/passtimes_lat.csv ${DATA_TARGET}
SAMPLEIMG=${DATA_TARGET}/20220914.terra.truecolor.250m.tiff

# Set up debug messages
export JULIA_DEBUG="Main,IFTPipeline,IceFloeTracker" 

# Run the processing
${IFT} landmask ${DATA_TARGET} ${DATA_TARGET}
${IFT} preprocess -t ${DATA_TARGET} -r ${DATA_TARGET} -l ${DATA_TARGET} -p ${DATA_TARGET} -o ${DATA_TARGET}
${IFT} extractfeatures -i ${DATA_TARGET} -o ${DATA_TARGET}
${IFT} track --imgs ${DATA_TARGET} --props ${DATA_TARGET} --passtimes ${DATA_TARGET} --latlon ${SAMPLEIMG} -o ${DATA_TARGET}
${IFT} makeh5files --pathtosampleimg ${SAMPLEIMG} --resdir ${DATA_TARGET}