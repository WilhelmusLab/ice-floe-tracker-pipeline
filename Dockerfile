FROM julia:1.9.0-bullseye

ENV TERM=xterm 

RUN apt-get install -y wget python3-pip git python3.10 
    #apt-get clean && apt-get update && \
    #&& \ rm -rf /var/lib/apt/list/*

WORKDIR /opt

RUN git clone https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git

RUN julia --project=/opt/ice-floe-tracker-pipeline -e 'ENV["PYTHON"]=""; using Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.precompile()'

RUN chmod a+x /opt/ice-floe-tracker-pipeline/workflow/scripts/ice-floe-tracker.jl

CMD [ "/bin/bash", "-c" ]