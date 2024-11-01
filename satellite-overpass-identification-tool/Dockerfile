FROM python:3.11-bullseye
ENV TERM=xterm
RUN python3 -m pip install pipx
COPY pass_time_cylc.py /opt/satellite-overpass-identification-tool/.
RUN pipx run /opt/satellite-overpass-identification-tool/pass_time_cylc.py --help
CMD [ "/bin/bash" ]
ENTRYPOINT [ "pipx", "run", "/opt/satellite-overpass-identification-tool/pass_time_cylc.py" ]
