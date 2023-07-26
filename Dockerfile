FROM julia:1.9-bookworm

ENV TERM=xterm
ENV JULIA_PROJECT=/opt/ice-floe-tracker-pipeline
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia

USER root

RUN apt-get -y update && \
    apt-get install -y git python3.10 && \
    rm -rf /var/lib/apt/list/*

WORKDIR /opt

RUN git clone https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git

RUN julia --project="/opt/ice-floe-tracker-pipeline" -e 'ENV["PYTHON"]=""; using Pkg; Pkg.instantiate(); Pkg.precompile(); Pkg.build("PyCall")' 

RUN chmod a+x /opt/ice-floe-tracker-pipeline/workflow/scripts/ice-floe-tracker.jl

ENV JULIA_DEPOT_PATH="$HOME/.julia:$JULIA_DEPOT_PATH"

CMD [ "/bin/bash", "-c" ]
