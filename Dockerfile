FROM julia:1.9-bookworm

# DEPENDENCIES
#===========================================
RUN apt-get -y update && \
    apt-get install -y git python3.10 && \
    rm -rf /var/lib/apt/list/* 

# JULIA ENVIRONMENT
#===========================================

ENV TERM=xterm
ENV JULIA=/usr/local/julia/bin/julia
ENV JULIA_DEPOT_PATH='/opt/julia'
ENV JULIA_PKGDIR='/opt/julia'

# Julia package build
#===========================================

ENV JULIA_PROJECT='/opt/ice-floe-tracker-pipeline/IFTPipeline.jl'

COPY ./IFTPipeline.jl ${JULIA_PROJECT}
RUN ${JULIA} --project=${JULIA_PROJECT} -e 'ENV["PYTHON"]=""; using Pkg; Pkg.build()'
RUN ${JULIA} --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.instantiate()'
ENV JULIA_DEPOT_PATH="/usr/local/bin/julia:$JULIA_DEPOT_PATH"

ENV LOCAL_PATH_TO_IFT_CLI="${JULIA_PROJECT}/src/cli.jl"
SHELL ["/bin/bash", "-c"]
ENTRYPOINT ${JULIA} --project=${JULIA_PROJECT} ${LOCAL_PATH_TO_IFT_CLI}
