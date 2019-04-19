#!/bin/bash

docker run -i -v '/root:/root' \
    -e NODE_IP="$NODE_IP" -e DEV_ENV="$DEV_ENV" \
    -e ORCHESTRATOR="$ORCHESTRATOR" -e OPENSTACK_VERSION="$OPENSTACK_VERSION" \
    contrail-dev-control
