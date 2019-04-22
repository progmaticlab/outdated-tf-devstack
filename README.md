# tf-devstack

tf-devstack is a tool for deployment of Contrail from published containers or building and deploying from sources.

It is similar to the OpenStack's devstack tool and
allows bringing up Contrail along with Kubernetes of OpenStack cloud on an all-in-one single node deployment.

## Hardware and software requirements

Recommended:
- AWS instance with 4 virtual CPU, 16 GB of RAM and 50 GB of disk space to deploy from published containers
- AWS instance with 4 virtual CPU, 16 GB of RAM and 80 GB of disk space to build and deploy from sources

Minimal:
- VirtualBox VM with 2 CPU, 8 GB of RAM and 30 GB of disk to deploy from published containers with Kubernetes.
- VirtualBox VM with 2 CPU, 10 GB of RAM and 30 GB of disk to deploy from published containers with OpenStack.

OS:
- Centos7
- or Ubuntu16.04 (under construction, not tested)

This scripts tested on a AWS node with Centos 7.

## Quick start on an AWS instance

1. Launch the new AWS instance.

Steps:
- CentOS 7 (x86_64) - with Updates HVM
- t2.xlarge instance type
- 50 GiB disk Storage

Log into a new instance and get root access:

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
Please, set variable BEFORE preparation script or restart preparation script:

```
export DEV_ENV=true
./prepare.sh
```

In this case, the instance must be rebooted manually after building and deployment.

Building step takes from one to two hours.

## Details

To deploy Contrail from published containers
[contrail-container-deployer playbooks](https://github.com/Juniper/contrail-ansible-deployer) is used. For building step
[contrail-dev-env environment](https://github.com/Juniper/contrail-dev-env) is used.

Preparation script allows root user to connect to host via ssh, install and configure docker,
build contrail-dev-control container.

Environment variable list:
- DEV_ENV true if build step is needed, false by default
- ORCHESTRATOR kubernetes by default or openstack
- K8S_VERSION kubernetes version, 1.12.3 is default for Centos, 1.12.7 is default for Ubuntu
- OPENSTACK_VERSION queens (default), ocata or rocky, variable used when ORCHESTRATOR=openstack
- NODE_IP a IP address used as CONTROLLER_NODES and CONTROL_NODES
- MASTER_NODE_IP a instance IP address 

## Known issues

- Deployment scripts are tested on CentOS 7 / Ubuntu 16.04 and AWS / Virtualbox
- Occasional errors prevent deployment of Kubernetes on a VirtualBox machine, retry can help
- One or more of Contrail containers are in "Restarting" status after installation,
try to wait 2-3 minutes or reboot the instance
- One or more pods in "Pending" state, try to "kubectl taint nodes NODENAME node-role.kubernetes.io/master-",
where NODENAME is name from "kubectl get node"
- OpenStack/rocky web UI reports "Something went wrong!",
try use CLI (you need install python-openstackclient in virtualenv)
- OpenStack/ocata can't find host to spawn VM,
set virt_type=qemu in [libvirt] section of /etc/kolla/config/nova/nova-compute.conf file inside nova_compute container,
then restart this container
