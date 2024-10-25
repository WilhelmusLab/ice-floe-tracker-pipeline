FROM julia:1.11-bookworm

# DEPENDENCIES
#===========================================
ENV TERM=xterm
RUN apt-get -y update && \
    apt-get install -y git python3.11 python3-pip python3-venv gdal-bin libgdal-dev

# Python environment build
#===========================================
WORKDIR /opt
RUN mkdir PyCallSetup

# Initialize an empty project which just has Conda and PyCall, in order to initialize an empty Conda `base` environment for PyCall
RUN julia --project=PyCallSetup -e 'ENV["PYTHON"]=""; using Pkg; Pkg.add("Conda"); Pkg.add("PyCall"); Pkg.build("PyCall");'

# Use conda to update the environment to have the correct version of python and other dependencies, then rebuild PyCall
COPY ./environment.yaml PyCallSetup/
RUN julia --project=PyCallSetup -e 'using Conda; Conda.runconda(Conda.Cmd(["env", "update", "-n", "base", "--file", "/opt/PyCallSetup/environment.yaml"])); using Pkg; Pkg.build("PyCall");'

# IFT Pipeline package build
#===========================================
# Now build the environment which we care about
ENV JULIA_PROJECT='/opt/ice-floe-tracker-pipeline/IFTPipeline.jl'
COPY ./IFTPipeline.jl ${JULIA_PROJECT}
RUN julia --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.instantiate(); Pkg.test();'

# RUN julia --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.instantiate(); Pkg.precompile(); Pkg.build(; verbose = true);'

# # CLI setup
# #===========================================

# SHELL ["/bin/bash", "-c"]
# ENV LOCAL_PATH_TO_IFT_CLI="${JULIA_PROJECT}/src/cli.jl"
# ENTRYPOINT ${JULIA} --project=${JULIA_PROJECT} ${LOCAL_PATH_TO_IFT_CLI}
