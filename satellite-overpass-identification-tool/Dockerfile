FROM python:3.11-bullseye
ENV TERM=xterm
RUN python3 -m pip install pipx
WORKDIR /opt
COPY satellite-overpass-identification-tool.py /opt/satellite-overpass-identification-tool/.
RUN pipx run /opt/satellite-overpass-identification-tool/satellite-overpass-identification-tool.py --help
CMD [ "/bin/bash" ]
ENTRYPOINT [ "pipx", "run", "/opt/satellite-overpass-identification-tool/satellite-overpass-identification-tool.py" ]
