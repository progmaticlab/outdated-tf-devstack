FROM centos

ENV USER root
ENV HOME /root/

RUN yum -y update \
&&  yum install -y python-setuptools \
&&  easy_install pip \
&&  pip install requests \
&&  pip install pyyaml==3.13 \
&&  yum install -y ansible-2.4.2.0 \
    iproute \
    git \
    gettext \
&&  yum clean all \
&&  rm -rf /var/cache/yum

RUN mkdir --parents /opt/control

ADD Dockerfile $HOME/

ADD control /opt/control

ENTRYPOINT "/opt/control/deploy.sh"
