# tf-devstack
tf-devstack is a series of scripts used to quickly bring up a complete Contrail Networking environment on a single node

## Node requirements

This scripts tested on a AWS node with Centos 7.
Recommended configuration is 16 GB of RAM and 50 GB of disk or more.
Minimal tested configuration is 10 GB of RAM.

## Installation steps

1. Launch the new AWS instance with Centos 7. Log into a new instance and get root access:

```
sudo su -
```

2. Clone this repository and run the preparation script:

```
git clone http://github.com/progmaticlab/tf-devstack
cd tf-stack
./prepare.sh
```

3. Start Contrail Networking deployment process:

```
./start.sh
```

4. Wait about 30-60 minutes to complete the deployment.

## Installation configuration

Contrail Networking is deployed with Kubernetes as orchestrator by default.
You can select OpenStack as orchestrator with environment variables before installation:

```
export ORCHESTRATOR=kubernetes
./start
```

## Building step

Work in progress.

## Known issues

- Deployment scripts tested on CentOS7 and AWS only
- Occasional errors prevents deployment Kubernetes on a VirtualBox machine
