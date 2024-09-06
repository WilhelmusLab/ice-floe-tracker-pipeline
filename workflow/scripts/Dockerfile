FROM python:3.9-bullseye

ENV TERM=xterm

RUN apt-get clean && apt-get update && \
    apt-get install -y wget python3-pip && \
    rm -rf /var/lib/apt/list/*

RUN apt-get install gdal-bin -y
<<<<<<< Updated upstream

RUN pip3 install skyfield \ 
        requests
=======
RUN pip3 install skyfield==1.45 \ 
        requests==2.31 \
	   opencv-python==4.10
>>>>>>> Stashed changes

COPY fetchdata.sh /usr/local/bin
COPY pass_time_cylc.py /usr/local/bin

RUN chmod a+x /usr/local/bin/pass_time_cylc.py
RUN chmod a+x /usr/local/bin/fetchdata.sh

CMD [ "/bin/bash", "-c" ]
