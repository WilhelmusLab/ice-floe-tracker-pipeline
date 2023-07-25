FROM julia:1.9.0-bullseye

ENV TERM=xterm 

RUN apt-get clean && apt-get update && \
    apt-get install -y wget python3-pip git python3.10 && \
    rm -rf /var/lib/apt/list/*

WORKDIR /opt

RUN git clone https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git

RUN julia --project=/opt/ice-floe-tracker-pipeline --compiled-modules=yes -e 'ENV["PYTHON"]=""; using Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.precompile(); Pkg.build("PyCall")' 

COPY /opt/ice-floe-tracker-pipeline/workflow/scripts/ice-floe-tracker.jl /usr/local/bin/ice-floe-tracker.jl
RUN chmod a+x /usr/local/bin/ice-floe-tracker.jl

CMD [ "/bin/bash", "-c" ]
