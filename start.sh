#!/bin/bash

docker run -i -v '/root:/root' \
    -e DEV_ENV="$DEV_ENV" -e ORCHESTRATOR="$ORCHESTRATOR" -e DEFAULT_NODE_IP="$DEFAULT_NODE_IP" \
    contrail-dev-control
