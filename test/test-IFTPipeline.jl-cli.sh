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
: "${FSDPROC:=pipx run --spec git+https://github.com/wilhelmuslab/ebseg fsdproc --debug}"
: "${COLORIZE:=pipx run --spec `pwd`/../label-colorizer colorize }"

# Set up debug messages
export JULIA_DEBUG="Main,IFTPipeline,IceFloeTracker" 

echo_CLI_tools () {
    echo "IFT=${IFT}"
    echo "FSDPROC=${FSDPROC}"
    echo "COLORIZE=${COLORIZE}"
}

initialize_test_directory () {
    DATA_SOURCE=$1
    DATA_TARGET=$2
    
    # Initialize data directory
    : "${DATA_SOURCE:=./input_data}"
    echo "DATA_SOURCE=${DATA_SOURCE}"

    : "${DATA_TARGET:=$(mktemp -d -p .)}"
    echo "DATA_TARGET=${DATA_TARGET}"

    mkdir -p ${DATA_TARGET}/

    cp -r ${DATA_SOURCE}/* ${DATA_TARGET}/
}

preprocess_lopez () {
    echo_CLI_tools

    DATA_SOURCE=$1
    DATA_TARGET=$2
    initialize_test_directory $1 $2

    LANDMASK=${DATA_TARGET}/landmask.tiff
    LANDMASK_NON_DILATED=${DATA_TARGET}/landmask.non-dilated.tiff
    LANDMASK_DILATED=${DATA_TARGET}/landmask.dilated.tiff
    TRUECOLOR=${DATA_TARGET}/truecolor.tiff
    FALSECOLOR=${DATA_TARGET}/falsecolor.tiff
    LABELED=${DATA_TARGET}/labeled.tiff
    COLORIZED=${DATA_TARGET}/labeled.colorized.tiff
    FLOEPROPERTIES=${DATA_TARGET}/labeled.props.csv
    HDF5FILE=${DATA_TARGET}/results.h5
    OVERPASS=${DATA_TARGET}/overpass.txt

    ${IFT} landmask_single \
        -i ${LANDMASK} \
        -o ${LANDMASK_NON_DILATED} \
        -d ${LANDMASK_DILATED}

    ${IFT} preprocess_single \
        --truecolor ${TRUECOLOR} \
        --falsecolor ${FALSECOLOR} \
        --landmask ${LANDMASK_NON_DILATED} \
        --landmask-dilated ${LANDMASK_DILATED} \
        --output ${LABELED}
    
    ${IFT} extractfeatures_single \
        --input ${LABELED} \
        --output ${FLOEPROPERTIES}

    ${COLORIZE} ${LABELED} ${COLORIZED}
    
    ${IFT} makeh5files_single \
        --passtime `cat ${OVERPASS}` \
        --truecolor ${TRUECOLOR} \
        --falsecolor ${FALSECOLOR} \
        --labeled ${LABELED} \
        --props ${FLOEPROPERTIES} \
        --output ${HDF5FILE}
}

preprocess_lopez_tiling () {
    echo_CLI_tools

    DATA_SOURCE=$1
    DATA_TARGET=$2
    initialize_test_directory $1 $2

    LANDMASK=${DATA_TARGET}/landmask.tiff
    LANDMASK_NON_DILATED=${DATA_TARGET}/landmask.non-dilated.tiff
    LANDMASK_DILATED=${DATA_TARGET}/landmask.dilated.tiff
    TRUECOLOR=${DATA_TARGET}/truecolor.tiff
    FALSECOLOR=${DATA_TARGET}/falsecolor.tiff
    SEGMENTED=${DATA_TARGET}/segmented.tiff
    LABELED=${DATA_TARGET}/labeled.tiff
    COLORIZED=${DATA_TARGET}/labeled.colorized.tiff
    FLOEPROPERTIES=${DATA_TARGET}/labeled.props.csv
    HDF5FILE=${DATA_TARGET}/results.h5
    OVERPASS=${DATA_TARGET}/overpass.txt

    ${IFT} landmask_single \
        -i ${LANDMASK} \
        -o ${LANDMASK_NON_DILATED} \
        -d ${LANDMASK_DILATED}

    ${IFT} preprocess_tiling_single \
        --truecolor ${TRUECOLOR} \
        --falsecolor ${FALSECOLOR} \
        --landmask-dilated ${LANDMASK_DILATED} \
        --segmented ${SEGMENTED} \
        --labeled ${LABELED}
    
    ${IFT} extractfeatures_single \
        --input ${LABELED} \
        --output ${FLOEPROPERTIES}

    ${COLORIZE} ${LABELED} ${COLORIZED}
    
    ${IFT} makeh5files_single \
        --passtime `cat ${OVERPASS}` \
        --truecolor ${TRUECOLOR} \
        --falsecolor ${FALSECOLOR} \
        --labeled ${LABELED} \
        --props ${FLOEPROPERTIES} \
        --output ${HDF5FILE}
}

preprocess_buckley () {
    echo_CLI_tools

    DATA_SOURCE=$1
    DATA_TARGET=$2
    initialize_test_directory $1 $2

    TRUECOLOR=${DATA_TARGET}/truecolor.tiff
    FALSECOLOR=${DATA_TARGET}/falsecolor.tiff
    CLOUD=${DATA_TARGET}/cloud.tiff
    LANDMASK=${DATA_TARGET}/landmask.tiff
    LABELED=${DATA_TARGET}/labeled.tiff
    COLORIZED=${DATA_TARGET}/labeled.colorized.tiff
    LABELEDDIR=${LABELED}.work/
    FLOEPROPERTIES=${DATA_TARGET}/labeled.props.csv
    HDF5FILE=${DATA_TARGET}/results.h5
    OVERPASS=${DATA_TARGET}/overpass.txt

    ${FSDPROC} process ${TRUECOLOR} ${CLOUD} ${LANDMASK} ${LABELEDDIR}
    cp ${LABELEDDIR}/final.tif ${LABELED}
    cp ${LABELEDDIR}/props.csv ${FLOEPROPERTIES}
    ${COLORIZE} ${LABELED} ${COLORIZED}
        
    ${IFT} makeh5files_single \
        --passtime `cat ${OVERPASS}` \
        --truecolor ${TRUECOLOR} \
        --falsecolor ${FALSECOLOR} \
        --labeled ${LABELED} \
        --props ${FLOEPROPERTIES} \
        --output ${HDF5FILE}
}


track () {
    echo_CLI_tools

    DATA_SOURCES=$@

    local DATA_ROOT
    : "${DATA_ROOT:=$(mktemp -d -p .)}"
    echo "DATA_ROOT=${DATA_ROOT}"

    DATA_ROOT_SUBDIRS=()
    
    for source in ${DATA_SOURCES[@]}
    do
        _THIS_SUBDIR=${DATA_ROOT}/$(basename $source)/
        DATA_ROOT_SUBDIRS+=(${_THIS_SUBDIR})
        ${PREPROCESS} ${source} ${_THIS_SUBDIR}
    done
    
    ${IFT} track_single \
        --imgs "${DATA_ROOT_SUBDIRS[@]/%/labeled.tiff}" \
        --props "${DATA_ROOT_SUBDIRS[@]/%/labeled.props.csv}" \
        --latlon "${DATA_ROOT_SUBDIRS[1]/%/truecolor.tiff}" \
        --passtimes $(cat ${DATA_ROOT_SUBDIRS[@]/%/overpass.txt} | tr '\n' ' ') \
        --output ${DATA_ROOT}/paired.csv
}


track_original () {
    PREPROCESS=preprocess_lopez track $@
}

track_lopez () {
    PREPROCESS=preprocess_lopez track $@
}

track_lopez_tiling () {
    PREPROCESS=preprocess_lopez_tiling track $@
}

track_buckley () {
    PREPROCESS=preprocess_buckley track $@
}
