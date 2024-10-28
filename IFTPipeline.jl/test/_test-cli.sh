#!/usr/bin/env bash

IFT="julia --project=../ ../src/cli.jl"

DATA_SOURCE=test_inputs/input_pipeline
TEMPDIR=$(mktemp -d -p __temp__)
cp ${DATA_SOURCE}/20220914.{terra,aqua}.{true,false}color.250m.tiff ${TEMPDIR}
cp ${DATA_SOURCE}/landmask.tiff ${TEMPDIR}
cp ${DATA_SOURCE}/passtimes_lat.csv ${TEMPDIR}
SAMPLEIMG=${TEMPDIR}/20220914.terra.truecolor.250m.tiff

${IFT} landmask ${TEMPDIR} ${TEMPDIR} 2>&1 | tee ${TEMPDIR}/landmask.log
${IFT} preprocess -t ${TEMPDIR} -r ${TEMPDIR} -l ${TEMPDIR} -p ${TEMPDIR} -o ${TEMPDIR} 2>&1 | tee ${TEMPDIR}/preprocess.log
${IFT} extractfeatures -i ${TEMPDIR} -o ${TEMPDIR}
${IFT} track --imgs ${TEMPDIR} --props ${TEMPDIR} --passtimes ${TEMPDIR} --latlon ${SAMPLEIMG} -o ${TEMPDIR}
${IFT} makeh5files --pathtosampleimg ${SAMPLEIMG} --resdir ${TEMPDIR}