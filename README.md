# Ansible runtime container for ppc64le

## About

A containmer image for running Ansible playbooks on an IBM Power Linux server.

Similar idea to an Ansible Execution Environment, but not identical.

This branch includes an Ansible inventory plugin for EYE (AIX healthcheck tool).

## Usage

To use this container image, mount your ssh keys and your project/playbook directory into the container:

```
podman run --rm -it -v $HOME/.ansible_ssh:/root/.ssh:Z,ro -v $PWD:/runner/project:Z,ro -w /runner/project localhost/ansible-runtime:1.0.0-ppc64le
```

Don't use your actual `~/.ssh/` directory if SELinux is in use, as podman will change the context, which will break sshd.

## Directory Contents

- `Containerfile`: podman Containerfile for ppc64le
- `Containerfile.amd64`: podman Containerfile for amd64
- `build.sh`: Script for building ppc64le image on iOCO build server & pushing to BackBlaze (EYE)
- `requirements.in`: List of Python modules to be installed
- `requirements.txt`: Python module constraints file (unused)
- `requirements.yml`: Ansible Galaxy collections to be installed
- `azul-inventory-1.0.6.tar.gz`: Ansible inventory collection for EYE
- `demo-playbook.yml`: Just a demo ;-)
