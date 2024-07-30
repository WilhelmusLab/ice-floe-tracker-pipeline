FROM julia:1.9-bookworm
ENV TERM=xterm
ENV JULIA_PROJECT=/opt/ice-floe-tracker-pipeline
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_BUILD='ENV["PYTHON"]=""; using Pkg; Pkg.build(); Pkg.instantiate()'
ENV IFTPIPELINE_REPO='https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git'
ENV LOCAL_PATH_TO_IFT_CLI='/usr/local/bin/ice-floe-tracker.jl'

RUN apt-get -y update && \
    apt-get install -y git python3.10 && \
    rm -rf /var/lib/apt/list/* 

WORKDIR /opt

RUN git clone --single-branch --branch main --depth 1 ${IFTPIPELINE_REPO}

RUN /usr/local/julia/bin/julia --project=${JULIA_PROJECT} -e ${JULIA_BUILD}

COPY workflow/scripts/ice-floe-tracker.jl /usr/local/bin/ice-floe-tracker.jl

RUN chmod a+x /usr/local/bin/ice-floe-tracker.jl

ENV JULIA_DEPOT_PATH="/usr/local/bin/julia:$JULIA_DEPOT_PATH"

CMD [ "/bin/bash", "-c" ]