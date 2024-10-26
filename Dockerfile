FROM julia:1.11-bookworm

# DEPENDENCIES
#===========================================
ENV TERM=xterm
RUN apt-get -y update && \
    apt-get install -y git python3.11 python3-pip python3-venv gdal-bin libgdal-dev


# IFT Pipeline package build
#===========================================
# Copy the files we need
ENV JULIA_PROJECT='/opt/ice-floe-tracker-pipeline/IFTPipeline.jl'
COPY ./IFTPipeline.jl ${JULIA_PROJECT}

# Setup Python
RUN julia --project=${JULIA_PROJECT} ${JULIA_PROJECT}/scripts/setup-python.jl

# Now build the environment which we care about
RUN julia --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.instantiate(); Pkg.test();'

# CLI setup
#===========================================
SHELL ["/bin/bash", "-c"]
ENV LOCAL_PATH_TO_IFT_CLI="${JULIA_PROJECT}/src/cli.jl"
ENTRYPOINT ${JULIA} --project=${JULIA_PROJECT} ${LOCAL_PATH_TO_IFT_CLI}
