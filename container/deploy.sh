#!/bin/bash

# test config variables

ORCHESTRATOR=${ORCHESTRATOR:-kubernetes}
DEV_ENV=${DEV_ENV:-false}

echo "Build from source: $DEV_ENV" # true or false
echo "Orchestrator: $ORCHESTRATOR" # kubernetes or openstack
echo

[ -d /opt/control/contrail-ansible-deployer ] && rm -rf /opt/control/contrail-ansible-deployer
cd /opt/control
git clone https://github.com/Juniper/contrail-ansible-deployer.git
cd /opt/control/contrail-ansible-deployer

# step 0

[ "$MASTER_NODE_IP" == "" ] && MASTER_NODE_IP=$(ip route get 1 | grep 'dev' | awk '{print ($3)}')

cat << EOF > /opt/control/host.yaml
[node]
$MASTER_NODE_IP
EOF

cat << EOF > /opt/control/pre.yaml
---
- hosts: node
  remote_user: root
  become: yes
  tasks:
  - name: check if pip present
    shell: pip --version
    ignore_errors: true
    register: pip_check

  - name: Install pip on RedHat family
    block:
      - name: install easy_install
        package:
          name: python-setuptools
          state: present
      - name: install pip package
        easy_install:
          name: pip
          state: latest
    when:
      - pip_check.rc != 0
      - ansible_os_family == 'RedHat'

  - name: Install pip on Debian family
    block:
      - name: install package
        apt:
          name: "{{ item }}"
          state: present
        register: res
        retries: 5
        until: res | success
        with_items:
          - python-setuptools
          - python-pip
    when:
      - pip_check.rc != 0
      - ansible_os_family == 'Debian'

  - name: Set ip forwarding on
    sysctl:
      name: net.ipv4.ip_forward
      value: 1
      state: present

  - name: Get default node interface
    shell: "ip route get 1 | grep -o 'dev.*' | awk '{print(\$2)}'"
    register: node_physical_interface

  - name: Get default node IP
    shell: "ip addr show dev {{ node_physical_interface.stdout }} | grep 'inet ' | awk '{print \$2}' | head -n 1 | cut -d '/' -f 1"
    register: default_node_ip

  - name: Store default node IP
    copy:
      dest: /opt/control/default_node_ip
      content: "{{ default_node_ip.stdout }}"
    delegate_to: localhost
EOF

ansible-playbook -i /opt/control/host.yaml /opt/control/pre.yaml

# detect build step variables

CONTAINER_REGISTRY="opencontrailnightly"
CONTRAIL_CONTAINER_TAG="ocata-master-latest"

if [ "$DEV_ENV" == "true" ]; then
    CONTAINER_REGISTRY="172.17.0.1:6666"
    CONTRAIL_CONTAINER_TAG="dev"

# build step

cat << EOF > /opt/control/build.yaml
---
- hosts: node
  remote_user: root
  become: yes
  tasks:
  - name: clean up dev-env repository path
    file:
      path: /opt/control/contrail-dev-env
      state: absent

  - name: install git package
    package:
      name: git
      state: present

  - name: clone dev-env repository
    git:
      repo: https://github.com/progmaticlab/contrail-dev-env.git
      dest: /root/contrail-dev-env
EOF

ansible-playbook -i /opt/control/host.yaml /opt/control/build.yaml

# build all

ssh root@$MASTER_NODE_IP "cd /root/contrail-dev-env && AUTOBUILD=1 BUILD_DEV_ENV=1 ./startup.sh"

fi

# detect default ip

DEFAULT_NODE_IP=$(</opt/control/default_node_ip)

[ "$NODE_IP" == "" ] && NODE_IP=$DEFAULT_NODE_IP
[ "$CONTROLLER_NODES" == "" ] && CONTROLLER_NODES=$DEFAULT_NODE_IP
[ "$CONTROL_NODES" == "" ] && CONTROL_NODES=$DEFAULT_NODE_IP

# generate inventory file for k8s all-in-one

if [ "$ORCHESTRATOR" == "kubernetes" ]; then

cat << EOF > /opt/control/instance.yaml
provider_config:
  bms:
    manage_etc_hosts: False
    domainsuffix: localdomain
    ssh_user: root
    ssh_pwd:
instances:
  server1:
    ip: $NODE_IP
    provider: bms
    roles:
      analytics: null
      analytics_snmp: null
      analytics_alarm: null
      analytics_database: null
      config: null
      config_database: null
      control: null
      device_manager: null
      webui: null
      k8s_master: null
      k8s_node: null
      kubemanager: null
      vrouter:
        AGENT_MODE: kernel
global_configuration:
  REGISTRY_PRIVATE_INSECURE: True
  CONTAINER_REGISTRY: $CONTAINER_REGISTRY
  K8S_VERSION: "1.12.3"
contrail_configuration:
  CONTRAIL_CONTAINER_TAG: $CONTRAIL_CONTAINER_TAG
  CONTROLLER_NODES: $CONTROLLER_NODES
  CONTROL_NODES: $CONTROL_NODES
  CONFIG_DATABASE_NODEMGR__DEFAULTS__minimum_diskGB: "2"
  DATABASE_NODEMGR__DEFAULTS__minimum_diskGB: "2"
  SSL_ENABLE: false
  RABBITMQ_USE_SSL: false
  CASSANDRA_SSL_ENABLE: false
  JVM_EXTRA_OPTS: "-Xms1g -Xmx2g"
  LOG_LEVEL: SYS_DEBUG
  CLOUD_ORCHESTRATOR: kubernetes
  VROUTER_ENCRYPTION: FALSE
  SELFSIGNED_CERTS_WITH_IPS: True
EOF

fi

# or generate inventory file for queens all-in-one

if [ "$ORCHESTRATOR" == "openstack" ]; then

OPENSTACK_VERSION=${OPENSTACK_VERSION:-queens}

cat << EOF > /opt/control/instance.yaml
provider_config:
  bms:
    ssh_pwd:
    ssh_user: root
    ntpserver: 169.254.169.123
    domainsuffix: local
instances:
  server1:
    provider: bms
    ip: $NODE_IP
    roles:
      config_database:
      config:
      control:
      analytics_database:
      analytics:
      webui:
      vrouter:
        AGENT_MODE: kernel
      openstack:
      openstack_compute:  
global_configuration:
  CONTAINER_REGISTRY: $CONTAINER_REGISTRY
  REGISTRY_PRIVATE_INSECURE: True
contrail_configuration:
  CLOUD_ORCHESTRATOR: openstack
  OPENSTACK_VERSION: $OPENSTACK_VERSION
  AUTH_MODE: keystone
  KEYSTONE_AUTH_URL_VERSION: /v3
  CONFIG_DATABASE_NODEMGR__DEFAULTS__minimum_diskGB: "2"
  DATABASE_NODEMGR__DEFAULTS__minimum_diskGB: "2"
  JVM_EXTRA_OPTS: "-Xms1g -Xmx2g"
kolla_config:
  kolla_globals:
    enable_haproxy: no
    enable_ironic: "no"
    enable_swift: "no"
    nova_compute_virt_type: qemu
    enable_barbican: no
  kolla_passwords:
    keystone_admin_password: contrail123
EOF

fi

# step 1

ansible-playbook -v -e orchestrator=$ORCHESTRATOR \
    -e config_file=/opt/control/instance.yaml \
    playbooks/configure_instances.yml

[ $? -gt 1 ] && echo Installation aborted && exit

# step 2

playbook_name="install_k8s.yml"
[ "$ORCHESTRATOR" == "openstack" ] && playbook_name="install_openstack.yml"

ansible-playbook -v -e orchestrator=$ORCHESTRATOR \
    -e config_file=/opt/control/instance.yaml \
    playbooks/$playbook_name

[ $? -gt 1 ] && echo Installation aborted && exit

# step 3

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
