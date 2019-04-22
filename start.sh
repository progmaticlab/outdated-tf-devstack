#!/bin/bash

docker run -i -v '/root:/root' \
    -e NODE_IP="$NODE_IP" -e MASTER_NODE_IP="$MASTER_NODE_IP" -e DEV_ENV="$DEV_ENV" \
    -e ORCHESTRATOR="$ORCHESTRATOR" -e K8S_VERSION="$K8S_VERSION" -e OPENSTACK_VERSION="$OPENSTACK_VERSION" \
    contrail-dev-control
