FROM python:3.11-bullseye
ENV TERM=xterm
RUN python3 -m pip install pipx
COPY . /opt/satellite-overpass-identification-tool/.
RUN pipx install --global /opt/satellite-overpass-identification-tool
ENTRYPOINT [ "soit" ]
