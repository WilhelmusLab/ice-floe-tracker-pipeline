FROM julia:1.9.0-bullseye

ENV TERM=xterm 

RUN apt-get clean && apt-get update && \
apt-get install -y git

RUN cd opt 

WORKDIR /opt

RUN git clone https://github.com/WilhelmusLab/ice-floe-tracker-pipeline.git

RUN julia -e 'using Pkg; Pkg.activate("/opt/IceFloeTracker"); ENV["PYTHON"]=""; Pkg.instantiate(); Pkg.build("PyCall")'

RUN julia -e 'using Pkg; Pkg.activate("/opt/ice-floe-tracker-pipeline"); Pkg.instantiate()'

#RUN julia --project='/opt/ice-floe-tracker-pipeline'

#COPY ./workflow/scripts/ice-floe-tracker.jl /opt/ice-floe-tracker-pipeline/workflow/scripts/

RUN chmod a+x /opt/ice-floe-tracker-pipeline/workflow/scripts/ice-floe-tracker.jl

CMD [ "/bin/bash", "-c" ]