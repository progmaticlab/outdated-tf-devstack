# tf-devstack

tf-devstack is a tool for deploy Contrail from published containers or build and deploy from sources.
It is similar to an OpenStack's devstack tool and
allows bringing up Contrail along with Kubernets of OpenStack cloud on an all-in-one single node deployment.

## Hardware and software requirements

Recommended:
- AWS instance with 16 GB of RAM and 50 GB of disk to deploy from published containers.
- AWS instance with 16 GB of RAM and 80 GB disk space to build and deploy from sources.

Minimal:
- VirtualBox VM with 10 GB of RAM and 50 GB of disk to deploy from published containers.

- Centos7
- or Ubuntu16.04 (under construction, not tested)

This scripts tested on a AWS node with Centos 7.

## Quick start on an AWS instance

1. Launch the new AWS instance. Log into a new instance and get root access:

```
sudo su -
```

2. Install git to clone this repository:

```
yum install -y git
```

3. Clone this repository and run the preparation script:

```
git clone http://github.com/progmaticlab/tf-devstack
cd tf-stack
./prepare.sh
```

4. Start Contrail Networking deployment process:

```
./start.sh
```

4. Wait about 30-60 minutes to complete the deployment.

## Installation configuration

Contrail Networking is deployed with Kubernetes as orchestrator by default.
You can select OpenStack as orchestrator with environment variables before installation.

```
export ORCHESTRATOR=openstack
export OPENSTACK_VERSION=queens
./start
```

OpenStack version may be selected from queens (default), ocata or rocky.

## Building step

Work in progress.

## Known issues

- Deployment scripts tested on CentOS 7 and AWS only
- OpenStack ocata version doesn't working properly on AWS
- Occasional errors prevents deployment Kubernetes on a VirtualBox machine
