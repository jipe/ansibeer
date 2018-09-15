# Ansibeer

Scripts for testing Ansible playbooks in a Docker container.

The name "Ansibeer" is derived from the similar project "Puppeteer" 
built for testing puppet modules in a Docker container.

## Prerequisites

Your Ansible repository needs to be available either in $HOME/ansible
or in a directory specified by the ANSIBLE_HOME environment variable.

## Using it

    $ ./run.sh --image <docker-image> <playbook>

Will run `ansible-playbook` inside a container and drop you to a prompt
for inspecting the container afterwards.

The docker image needs to have Ansible installed. If this is not the
case, you can put a Dockerfile that will install Ansible with the same
name as the image in the `dockerfiles` directory and Ansibeer will
build an image from that and use that instead of the original image.

There are convenience scripts for using `debian:jessie` and `debian:stretch`.
These are `jessie.sh` and `stretch.sh` respectively. So you could test on
a Debian Jessie container with

    $ ./jessie <playbook>

The `playbooks` directory is in `.gitignore`, so that is a perfectly fine
place for putting your experimental playbooks you want to test.
