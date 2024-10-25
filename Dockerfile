FROM julia:1.9-bookworm
ENV TERM=xterm
ENV JULIA=/usr/local/julia/bin/julia
ENV JULIA_DEPOT_PATH='/opt/julia'
ENV JULIA_PKGDIR='/opt/julia'
ENV IFTPIPELINE_REPO='https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git'
ENV JULIA_PROJECT='/opt/ice-floe-tracker-pipeline/IFTPipeline.jl'
ENV LOCAL_PATH_TO_IFT_CLI="${JULIA_PROJECT}/src/cli.jl"

WORKDIR /opt

# DEPENDENCIES
#===========================================
RUN apt-get -y update && \
    apt-get install -y git python3.10 && \
    rm -rf /var/lib/apt/list/* 

# Julia package build
#===========================================

RUN git clone --single-branch --branch main --depth 1 ${IFTPIPELINE_REPO} ${JULIA_PROJECT}
RUN ${JULIA} --project=${JULIA_PROJECT} -e 'ENV["PYTHON"]=""; using Pkg; Pkg.build()'
RUN ${JULIA} --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.instantiate()'
ENV JULIA_DEPOT_PATH="/usr/local/bin/julia:$JULIA_DEPOT_PATH"
ENTRYPOINT [ ${JULIA}, "--project=${JULIA_PROJECT}", ${LOCAL_PATH_TO_IFT_CLI} ]
