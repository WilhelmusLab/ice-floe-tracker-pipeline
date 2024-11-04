FROM python:3.9-bullseye

ENV TERM=xterm

# DEPENDENCIES
#===========================================
RUN apt-get clean && apt-get update && \
    apt-get install -y wget python3-pip && \
    rm -rf /var/lib/apt/list/*
RUN apt-get install gdal-bin -y
RUN pip3 install skyfield \ 
        requests

# Build software
#===========================================
COPY fetchdata.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/fetchdata.sh
CMD [ "/bin/bash", "-c" ]
