#!/bin/bash

[ "$(whoami)" != "root" ] && echo Please run script as root user && exit

# prepare ssh key authorization

[ ! -d /root/.ssh ] && mkdir /root/.ssh && chmod 0700 /root/.ssh
[ ! -f /root/.ssh/id_rsa ] && ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -N ''
[ ! -f /root/.ssh/authorized_keys ] && touch /root/.ssh/authorized_keys && chmod 0600 /root/.ssh/authorized_keys
grep "$(</root/.ssh/id_rsa.pub)" /root/.ssh/authorized_keys -q || cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# detect build step variables

CONTAINER_REGISTRY="opencontrailnightly"

if [ "$DEV_ENV" == "true" ]; then
    CONTAINER_REGISTRY="172.17.0.1:6666"
    # disable firewall
    systemctl stop firewalld || true
fi

# docker installation

cat << EOF > /etc/yum.repos.d/docker-ce.repo
[docker-ce-18.03.1.ce]
name=docker-ce-18.03.1.ce repository
baseurl=https://download.docker.com/linux/centos/7/x86_64/stable
enabled=1
EOF
rpm --import https://download.docker.com/linux/centos/gpg
yum install docker-ce-18.03.1.ce -y

# docker launch

if [ ! -f /etc/sysconfig/docker-storage ]; then
cat << EOF > /etc/sysconfig/docker-storage
DOCKER_STORAGE_OPTIONS="--storage-opt dm.basesize=20G"
EOF
fi

if [ ! -d /etc/docker ]; then
mkdir /etc/docker
cat << EOF > /etc/docker/daemon.json
{
    "insecure-registries": [
        "$CONTAINER_REGISTRY"
    ]
}
EOF
fi

systemctl enable docker
systemctl start docker

# control node image preparation

function is_builded () {
  local container=$1
  docker image ls -a --format '{{.Repository}}' | grep "$container" > /dev/null
  return $?
}

if ! is_builded "contrail-dev-control"; then
  docker build -t contrail-dev-control ./container
  echo contrail-dev-control created.
fi

# show current node configuration

PHYSICAL_INTERFACE=$(ip route get 1 | grep -o 'dev.*' | awk '{print($2)}')
DEFAULT_NODE_IP=$(ip addr show dev $PHYSICAL_INTERFACE | grep 'inet ' | awk '{print $2}' | head -n 1 | cut -d '/' -f 1)
echo "NODE IP $DEFAULT_NODE_IP"
[ "$DEV_ENV" == "true" ] && echo "BUILD STEP WILL BE INCLUDED"
