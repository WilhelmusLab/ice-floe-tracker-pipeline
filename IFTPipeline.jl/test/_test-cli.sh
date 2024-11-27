#!/usr/bin/env bash

# Scripts
IFT="julia --project=../ ../src/cli.jl"

# Data source and target
DATA_SOURCE=test_inputs/input_pipeline
TEMPDIR=$(mktemp -d -p __temp__)
echo "TEMPDIR=${TEMPDIR}"

# Initialize data directory
cp ${DATA_SOURCE}/20220914.{terra,aqua}.{true,false}color.250m.tiff ${TEMPDIR}
cp ${DATA_SOURCE}/landmask.tiff ${TEMPDIR}
cp ${DATA_SOURCE}/passtimes_lat.csv ${TEMPDIR}
SAMPLEIMG=${TEMPDIR}/20220914.terra.truecolor.250m.tiff

# Set up debug messages
export JULIA_DEBUG="Main,IFTPipeline,IceFloeTracker" 

# Run the processing
${IFT} landmask ${TEMPDIR} ${TEMPDIR}
${IFT} preprocess -t ${TEMPDIR} -r ${TEMPDIR} -l ${TEMPDIR} -p ${TEMPDIR} -o ${TEMPDIR}
${IFT} extractfeatures -i ${TEMPDIR} -o ${TEMPDIR}
${IFT} track --imgs ${TEMPDIR} --props ${TEMPDIR} --passtimes ${TEMPDIR} --latlon ${SAMPLEIMG} -o ${TEMPDIR}
${IFT} makeh5files --pathtosampleimg ${SAMPLEIMG} --resdir ${TEMPDIR}