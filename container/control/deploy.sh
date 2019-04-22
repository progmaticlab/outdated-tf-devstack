#!/bin/bash

# show config variables

ORCHESTRATOR=${ORCHESTRATOR:-kubernetes}
DEV_ENV=${DEV_ENV:-false}
OPENSTACK_VERSION=${OPENSTACK_VERSION:-queens}

[ "$NODE_IP" != "" ] && echo "Node IP: NODE_IP"
echo "Build from source: $DEV_ENV" # true or false
echo "Orchestrator: $ORCHESTRATOR" # kubernetes or openstack
[ "$ORCHESTRATOR" == "kubernetes" ] && [ "$K8S_VERSION" != "" ] && echo "Kubernetes version: $K8S_VERSION"
[ "$ORCHESTRATOR" == "openstack" ] && echo "OpenStack version: $OPENSTACK_VERSION"
echo

# get contrail-ansible-deployer from git

[ -d /opt/control/contrail-ansible-deployer ] && rm -rf /opt/control/contrail-ansible-deployer
cd /opt/control
git clone https://github.com/Juniper/contrail-ansible-deployer.git
cd /opt/control/contrail-ansible-deployer

# step 0 - prepare master node, detect default ip

[ "$MASTER_NODE_IP" == "" ] && MASTER_NODE_IP=$(ip route get 1 | grep 'dev' | awk '{print ($3)}')
export MASTER_NODE_IP
envsubst < /opt/control/host_template.yaml > /opt/control/host.yaml

ansible-playbook -i /opt/control/host.yaml /opt/control/pre.yaml

# default env variables

CONTAINER_REGISTRY="opencontrailnightly"
CONTRAIL_CONTAINER_TAG="ocata-master-latest"

# build step

if [ "$DEV_ENV" == "true" ]; then
    # build all
    ansible-playbook -i /opt/control/host.yaml /opt/control/build-pre.yaml
    ssh root@$MASTER_NODE_IP "cd /root/contrail-dev-env && AUTOBUILD=1 BUILD_DEV_ENV=1 ./startup.sh"
    ansible-playbook -i /opt/control/host.yaml /opt/control/build-post.yaml

    # fix env variables
    CONTAINER_REGISTRY="$(</opt/control/registry_ip):6666"
    CONTRAIL_CONTAINER_TAG="dev"
fi

# generate inventory file

[ "$NODE_IP" == "" ] && NODE_IP=$(</opt/control/default_node_ip)

if [ "$K8S_VERSION" == "" ]; then
    if [ "$(</opt/control/node_distro)" == "ubuntu" ]; then
        K8S_VERSION="1.12.7"
    else
        K8S_VERSION="1.12.3"
    fi
fi

export NODE_IP
export CONTAINER_REGISTRY
export CONTRAIL_CONTAINER_TAG
export K8S_VERSION
export OPENSTACK_VERSION
envsubst < /opt/control/instance_$ORCHESTRATOR.yaml > /opt/control/instance.yaml

# step 1 - configure instances

ansible-playbook -v -e orchestrator=$ORCHESTRATOR \
    -e config_file=/opt/control/instance.yaml \
    playbooks/configure_instances.yml

[ $? -gt 1 ] && echo Installation aborted && exit

# step 2 - install orchestrator

playbook_name="install_k8s.yml"
[ "$ORCHESTRATOR" == "openstack" ] && playbook_name="install_openstack.yml"

ansible-playbook -v -e orchestrator=$ORCHESTRATOR \
    -e config_file=/opt/control/instance.yaml \
    playbooks/$playbook_name

[ $? -gt 1 ] && echo Installation aborted && exit

# step 3 - install contrail

ansible-playbook -v -e orchestrator=$ORCHESTRATOR \
    -e config_file=/opt/control/instance.yaml \
    playbooks/install_contrail.yml

[ $? -gt 1 ] && echo Installation aborted

# show results

echo
echo Deployment scripts are finished
[ "$DEV_ENV" == "true" ] && echo Please reboot node before testing
echo Contrail Web UI must be available at https://$NODE_IP:8143
[ "$ORCHESTRATOR" == "openstack" ] && echo OpenStack UI must be avaiable at http://$NODE_IP
echo Use admin/contrail123 to log in
