FROM julia:1.9.0-bullseye

ENV TERM=xterm 

RUN apt-get clean && apt-get update && \
apt-get install -y git

RUN cd opt 

WORKDIR /opt

RUN git clone https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git && \ 
git clone https://github.com/WilhelmusLab/IceFloeTracker.jl.git IceFloeTracker

RUN julia -e 'using Pkg; Pkg.activate("/opt/IceFloeTracker"); ENV["PYTHON"]=""; Pkg.instantiate(); Pkg.build("PyCall")'

RUN julia -e 'using Pkg; Pkg.activate("/opt/ice-floe-tracker-pipeline"); Pkg.rm("IceFloeTracker"); Pkg.add(path="/opt/IceFloeTracker"); Pkg.instantiate()'

#RUN julia --project='/opt/ice-floe-tracker-pipeline'

COPY ./workflow/scripts/ice-floe-tracker.jl /usr/local/bin

RUN chmod a+x /usr/local/bin/ice-floe-tracker.jl

CMD [ "/bin/bash", "-c" ]