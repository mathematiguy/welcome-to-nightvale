FROM sorokine/docker-colab-local:10.2

RUN apt update
RUN apt install unzip

RUN pip uninstall -y enum34

COPY requirements.txt /root/requirements.txt
RUN pip install -r /root/requirements.txt
