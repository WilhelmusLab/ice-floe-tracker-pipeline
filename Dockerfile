FROM julia:1.11-bookworm

# DEPENDENCIES
#===========================================
ENV TERM=xterm
RUN apt-get -y update && \
    apt-get install -y git python3.11 python3-pip python3-venv gdal-bin libgdal-dev

# Python environment build
#===========================================
ENV VENV_PATH=/opt/venv
RUN /bin/python3.11 -m venv ${VENV_PATH}
COPY ./requirements.txt ${VENV_PATH}/requirements.txt
RUN ${VENV_PATH}/bin/pip install -r ${VENV_PATH}/requirements.txt
ENV PYTHON=${VENV_PATH}/bin/python
RUN ${PYTHON} -c "import rasterio; print(rasterio)"

# IFT Pipeline package build
#===========================================
ENV JULIA_PROJECT='/opt/ice-floe-tracker-pipeline/IFTPipeline.jl'
COPY ./IFTPipeline.jl ${JULIA_PROJECT}
RUN julia --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.instantiate(); Pkg.precompile(); Pkg.build(; verbose = true);'

# CLI setup
#===========================================

SHELL ["/bin/bash", "-c"]
# ENV LOCAL_PATH_TO_IFT_CLI="${JULIA_PROJECT}/src/cli.jl"
# ENTRYPOINT ${JULIA} --project=${JULIA_PROJECT} ${LOCAL_PATH_TO_IFT_CLI}
