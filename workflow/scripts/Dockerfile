FROM python:3.9-bullseye

ENV TERM=xterm

RUN apt-get clean && apt-get update && \
    apt-get install -y wget python3-pip && \
    rm -rf /var/lib/apt/list/*

RUN apt-get install gdal-bin -y

RUN pip3 install skyfield \ 
        requests

COPY fetchdata.sh /usr/local/bin
COPY pass_time_cylc_hpc.py /usr/local/bin
COPY pass_time_cylc_local.py /usr/local/bin

RUN chmod a+x /usr/local/bin/pass_time_cylc_hpc.py
RUN chmod a+x /usr/local/bin/pass_time_cylc_local.py
RUN chmod a+x /usr/local/bin/fetchdata.sh

CMD [ "/bin/bash", "-c" ]
