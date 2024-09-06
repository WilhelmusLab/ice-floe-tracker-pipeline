FROM python:3.9-bullseye

ENV TERM=xterm

# DEPENDENCIES
#===========================================
RUN apt-get clean && apt-get update && \
    apt-get install -y wget python3-pip && \
    rm -rf /var/lib/apt/list/*
RUN apt-get install gdal-bin -y

RUN pip3 install skyfield==1.45 \
        requests==2.31.0 \ 
        opencv-python==4.10.0.84

# Build software
#===========================================
COPY fetchdata.sh /usr/local/bin
COPY pass_time_cylc.py /usr/local/bin
RUN chmod a+x /usr/local/bin/pass_time_cylc.py
RUN chmod a+x /usr/local/bin/fetchdata.sh
CMD [ "/bin/bash", "-c" ]
