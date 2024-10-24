FROM julia:1.9-bookworm
ENV TERM=xterm
ENV JULIA_PROJECT=/opt/ice-floe-tracker-pipeline/IFTPipeline.jl
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_BUILD='ENV["PYTHON"]=""; using Pkg; Pkg.build()'
ENV IFTPIPELINE_REPO='https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git'
ENV LOCAL_PATH_TO_IFT_CLI='/usr/local/bin/ice-floe-tracker.jl'

WORKDIR /opt

# DEPENDENCIES
#===========================================
RUN apt-get -y update && \
    apt-get install -y git python3.10 && \
    rm -rf /var/lib/apt/list/* 

# Julia package build
#===========================================

RUN git clone --single-branch --branch main --depth 1 ${IFTPIPELINE_REPO}
RUN /usr/local/julia/bin/julia --project=${JULIA_PROJECT} -e ${JULIA_BUILD}
RUN /usr/local/julia/bin/julia --project=${JULIA_PROJECT} -e 'using Pkg; Pkg.instantiate()'
COPY workflow/scripts/ice-floe-tracker.jl ${LOCAL_PATH_TO_IFT_CLI}
RUN chmod a+x ${LOCAL_PATH_TO_IFT_CLI}
ENV JULIA_DEPOT_PATH="/usr/local/bin/julia:$JULIA_DEPOT_PATH"
CMD [ "/bin/bash", "-c" ]
