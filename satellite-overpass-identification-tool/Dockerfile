FROM python:3.11-bullseye

ENV TERM=xterm
RUN python3 -m pip install pipx


# DEPENDENCIES
#===========================================
WORKDIR /opt
ENV PIPX_HOME=/opt/pipx 
ENV PIPX_BIN_DIR=/usr/local/bin
COPY satellite-overpass-identification-tool.py /opt/satellite-overpass-identification-tool/.

# RUN pipx install /opt/satellite-overpass-identification-tool/satellite-overpass-identification-tool.py
# ENTRYPOINT [ "/usr/local/bin/satellite-overpass-identification-tool" ]

CMD [ "/bin/bash" ]