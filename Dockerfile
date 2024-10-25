FROM julia:1.9-bookworm

# DEPENDENCIES
#===========================================
ENV TERM=xterm
RUN apt-get -y update && \
    apt-get install -y git python3.11 python3-pip python3-venv gdal-bin libgdal-dev
ENV PYTHON=/bin/python3.11

# Python environment build
#===========================================
ENV VENV_PATH=/opt/venv
RUN ${PYTHON} -m venv ${VENV_PATH}
COPY ./requirements.txt ${VENV_PATH}/requirements.txt
RUN ${VENV_PATH}/bin/pip install -r ${VENV_PATH}/requirements.txt

# IFT Pipeline package build
#===========================================

# ENV JULIA=/usr/local/julia/bin/julia
# ENV JULIA_DEPOT_PATH='/opt/julia'
# ENV JULIA_PKGDIR='/opt/julia'
# ENV JULIA_PROJECT='/opt/ice-floe-tracker-pipeline/IFTPipeline.jl'
# COPY ./IFTPipeline.jl ${JULIA_PROJECT}
# RUN ${JULIA} --project=${JULIA_PROJECT} -e 'ENV["PYTHON"]="${VENV_PATH}/bin/python"; using Pkg; Pkg.build()'
# RUN ${JULIA} --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.instantiate()'
# ENV JULIA_DEPOT_PATH="/usr/local/bin/julia:$JULIA_DEPOT_PATH"

# # CLI setup
# #===========================================

# ENV LOCAL_PATH_TO_IFT_CLI="${JULIA_PROJECT}/src/cli.jl"
# SHELL ["/bin/bash", "-c"]
# ENTRYPOINT ${JULIA} --project=${JULIA_PROJECT} ${LOCAL_PATH_TO_IFT_CLI}
