FROM ubuntu:16.04
MAINTAINER NSCPX-Dev <NSCPX-Dev@citrite.net>
RUN apt-get update

RUN mkdir -p /tmp/nitroSDK/
COPY build/ubuntu_requirements.txt /tmp/nitroSDK
COPY build/pip_requirements.txt /tmp/nitroSDK
RUN apt-get update
RUN cat /tmp/nitroSDK/ubuntu_requirements.txt | xargs apt-get install -yq
RUN (cd /tmp/nitroSDK && wget -q http://downloadns.citrix.com.edgesuite.net/15691/ns-12.1-48.137-nitro-python.tgz)
RUN (cd /tmp/nitroSDK && tar xzf ns-12.1-48.137-nitro-python.tgz && \
    tar xf ns_nitro-python_kamet_48_137.tar && \
    cd nitro-python-*/ && \
    python setup.py install && \
    cd / && \
    rm -rf /tmp/nitroSDK/ && \
    mkdir -p /usr/src/)

COPY build/pip_requirements.txt .
RUN pip install -r pip_requirements.txt

COPY src/*.pyc /usr/src/triton/
COPY build/triton_startup.sh /usr/src/triton/
COPY src/swarm/*.pyc /usr/src/triton/swarm/
COPY src/marathon/*.pyc  /usr/src/triton/marathon/
COPY src/kubernetes/*.pyc  /usr/src/triton/kubernetes/
COPY src/kubernetes/crd/*.pyc  /usr/src/triton/kubernetes/crd/
COPY src/nsappinterface/*.pyc  /usr/src/triton/nsappinterface/
COPY src/stats/*.pyc   /usr/src/triton/stats/
COPY src/libs/*.pyc   /usr/src/triton/libs/
COPY version/VERSION           /usr/src/triton/
COPY version/BUILD_LABEL    /usr/src/triton/
RUN echo "alias version='cat /usr/src/triton/VERSION /usr/src/triton/BUILD_LABEL'" >> /root/.bashrc
ENTRYPOINT ["bash", "/usr/src/triton/triton_startup.sh"]
