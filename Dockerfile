FROM julia:1.9-bookworm

ENV TERM=xterm
ENV JULIA_PROJECT=/opt/ice-floe-tracker-pipeline
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia

# TODO: add versions python3-pyproj=3.6.0 python3-rasterio=1.3.7
RUN apt-get clean && apt-get update && \
    apt-get install -y wget python3.10 python3-pip git && \
    apt-get install -y python3-pyproj python3-rasterio && \
    rm -rf /var/lib/apt/list/*

WORKDIR /opt

RUN git clone https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git

RUN julia --project="/opt/ice-floe-tracker-pipeline" -e 'ENV["PYTHON"]="/usr/local/bin/python"; using Pkg; Pkg.instantiate(); Pkg.precompile(); Pkg.build("PyCall")' 

RUN chmod a+x /opt/ice-floe-tracker-pipeline/workflow/scripts/ice-floe-tracker.jl

ENV JULIA_DEPOT_PATH="$HOME/.julia:$JULIA_DEPOT_PATH"

CMD [ "/bin/bash", "-c" ]
