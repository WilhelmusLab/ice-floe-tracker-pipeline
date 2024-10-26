FROM julia:1.11-bookworm

# DEPENDENCIES
#===========================================
ENV TERM=xterm
RUN apt-get -y update && \
    apt-get install -y git python3.11 python3-pip python3-venv gdal-bin libgdal-dev

# Python environment build
#===========================================
ENV PYTHON_SETUP_PROJECT='/opt/PythonSetup.jl'
COPY ./PythonSetup.jl ${PYTHON_SETUP_PROJECT}
RUN julia --project=${PYTHON_SETUP_PROJECT} ${PYTHON_SETUP_PROJECT}/setup.jl

# IFT Pipeline package build
#===========================================
ENV JULIA_PROJECT='/opt/IFTPipeline.jl'
COPY ./IFTPipeline.jl ${JULIA_PROJECT}
RUN julia --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.instantiate();'

# Test the package
RUN julia --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.test();'

# CLI setup
#===========================================
SHELL ["/bin/bash", "-c"]
ENV LOCAL_PATH_TO_IFT_CLI="${JULIA_PROJECT}/src/cli.jl"
ENTRYPOINT ${JULIA} --project=${JULIA_PROJECT} ${LOCAL_PATH_TO_IFT_CLI}
