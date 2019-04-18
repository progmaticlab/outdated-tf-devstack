# tf-devstack

tf-devstack is a tool for deploy Contrail from published containers or build and deploy from sources.

It is similar to an OpenStack's devstack tool and
allows bringing up Contrail along with Kubernets of OpenStack cloud on an all-in-one single node deployment.

## Hardware and software requirements

Recommended:
- AWS instance with 4 virtual CPU, 16 GB of RAM and 50 GB of disk space to deploy from published containers
- AWS instance with 4 virtual CPU, 16 GB of RAM and 80 GB of disk space to build and deploy from sources

Minimal:
- VirtualBox VM with 2 CPU, 10 GB of RAM and 50 GB of disk to deploy from published containers.

OS:
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
cd tf-devstack
./prepare.sh
```

4. Start Contrail Networking deployment process:

```
./start.sh
```

5. Wait about 30-60 minutes to complete the deployment.

## Installation configuration

Contrail Networking is deployed with Kubernetes as orchestrator by default.
You can select OpenStack as orchestrator with environment variables before installation.

```
export ORCHESTRATOR=openstack
export OPENSTACK_VERSION=queens
./start.sh
```

OpenStack version may be selected from queens (default), ocata or rocky.

## Building step

Environment variable DEV_ENV may be defined as "true" to build Contrail from sources.
Please, set variable BEFORE preparation script:

```
export DEV_ENV=true
./prepare.sh
```

In this case, the instance must be rebooted manually after building and deployment.

## Details

To deploy Contrail from published containers used
[contrail-container-deployer playbooks](https://github.com/Juniper/contrail-ansible-deployer). For building step used
[contrail-dev-env environment](https://github.com/Juniper/contrail-dev-env).

Preparation script allow root user to connect to host via ssh, install and configure docker,
build contrail-dev-control container.

Environment variable list:
- DEFAULT_NODE_IP a IP address used as CONTROLLER_NODES and CONTROL_NODES
- DEV_ENV true if build step is needed, false by default
- ORCHESTRATOR kubernetes by default or openstack
- OPENSTACK_VERSION queens (default), ocata or rocky, variable used when ORCHESTRATOR=openstack

## Known issues

- Deployment scripts tested on CentOS 7 and AWS only
- OpenStack ocata version doesn't working properly on AWS
- Occasional errors prevents deployment Kubernetes on a VirtualBox machine, retry can help
- One or more Contrail containers are in "Restarting" status after installation,
try to wait a 2-3 minutes or reboot the instance
- One or more pods in "Pending" status, try to "kubectl taint nodes NODENAME node-role.kubernetes.io/master-",
where NODENAME is name from "kubectl get node"
