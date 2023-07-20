FROM julia:1.9.0-bullseye

ENV TERM=xterm 

RUN apt-get clean && apt-get update && \
    apt-get install -y wget python3-pip git python3.10 && \
    rm -rf /var/lib/apt/list/*

RUN cd opt 

WORKDIR /opt

RUN pip3 install -U scikit-image==0.20.0 pyproj==3.6.0 rasterio==1.3.7 requests==2.31.0 skyfield==1.45.0

RUN git clone https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git

#RUN julia -e 'using Pkg; Pkg.activate("/opt/IceFloeTracker"); ENV["PYTHON"]=""; Pkg.instantiate(); Pkg.build("PyCall")'

RUN julia -e 'using Pkg; Pkg.activate("/opt/ice-floe-tracker-pipeline"); Pkg.instantiate()'

RUN chmod a+x /opt/ice-floe-tracker-pipeline/workflow/scripts/ice-floe-tracker.jl

CMD [ "/bin/bash", "-c" ]