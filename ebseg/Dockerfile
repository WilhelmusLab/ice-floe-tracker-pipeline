FROM julia:1.9-bookworm

ENV TERM=xterm
ENV JULIA_PROJECT=/opt/ice-floe-tracker-pipeline
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_BUILD_PYCALL='ENV["PYTHON"]=""; using Pkg; Pkg.build()'
ENV EBSEG_REPO='https://github.com/WilhelmusLab/ebseg.git'
ENV IFTPIPELINE_REPO='https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git'
ENV LOCAL_PATH_TO_IFT_CLI='/usr/local/bin/ice-floe-tracker.jl'

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
RUN pip install --upgrade pip --break-system-packages

RUN pip install git+${EBSEG_REPO} \
    jinja2==3.1 \
    pyproj==3.6 \
    requests==2.31 \
    skyfield==1.45 \
    --break-system-packages

WORKDIR /opt

# Julia package build
#===========================================
RUN git clone --single-branch --branch main --depth 1 ${IFTPIPELINE_REPO}
RUN julia --project=${JULIA_PROJECT} -e ${JULIA_BUILD_PYCALL}
RUN julia -e 'using Pkg; Pkg.instantiate()'

# Final setup
#===========================================
COPY ../workflow/scripts/ice-floe-tracker.jl ${LOCAL_PATH_TO_IFT_CLI}
RUN chmod a+x ${LOCAL_PATH_TO_IFT_CLI}
ENV JULIA_DEPOT_PATH="/home/.julia:$JULIA_DEPOT_PATH"
CMD ["/bin/bash"]
