FROM julia:1.9-bookworm

ENV TERM=xterm
ENV JULIA_PROJECT=/opt/ice-floe-tracker-pipeline
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia

# DEPENDENCIES
#===========================================
RUN apt-get update -y && \
    apt-get -qq install -y \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    yasm \
    pkg-config \
    libswscale-dev \
    libtbb-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libopenjp2-7-dev \
    libavformat-dev \
    libpq-dev \
    python3.11 python3-pip

# Python packages
#===========================================
RUN pip install --upgrade pip --break-system-packages && \
    pip install git+https://github.com/WilhelmusLab/ebseg.git --break-system-packages

WORKDIR /opt

RUN git clone https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git

RUN /usr/local/julia/bin/julia --project="/opt/ice-floe-tracker-pipeline" -e 'ENV["PYTHON"]=""; using Pkg; Pkg.build()'

COPY workflow/scripts/ice-floe-tracker.jl /usr/local/bin/ice-floe-tracker.jl

RUN chmod a+x /usr/local/bin/ice-floe-tracker.jl

ENV JULIA_DEPOT_PATH="$HOME/.julia:$JULIA_DEPOT_PATH"

CMD [ "/bin/bash", "-c" ]
