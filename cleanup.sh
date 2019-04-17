#!/bin/bash

docker container prune -f

image_name="contrail-dev-control"
docker image rm $(docker images -a -q $image_name)
