# Ansibeer

Scripts for testing Ansible playbooks in a Docker container.

The name "Ansibeer" is derived from the similar project "Puppeteer" 
built for testing puppet modules in a Docker container.

## Prerequisites

You need to have Docker installed.

## Using it

    $ ./run.sh --image <docker-image> <playbook>

Will run `ansible-playbook` inside a container and drop you to a prompt
for inspecting the container afterwards. Your Ansible repository is assumed
to be in `$HOME/ansible` or you can specify it either using the `-a` argument
or by setting the `ANSIBLE_HOME` environment variable to point to its location.

The docker image needs to have Ansible installed. If this is not the
case, you can put a Dockerfile that will install Ansible with the same
name as the image in the `dockerfiles` directory and Ansibeer will
build an image from that and use that instead of the original image.

There is a convenience script for using `debian:stretch` called `stretch.sh`.
You could test on a Debian Stretch container with

    $ ./stretch.sh <playbook>

The `playbooks` directory is in `.gitignore`, so that is a perfectly fine
place for putting your experimental playbooks you want to test.

## Testing systemd services and Docker containers

Ansibeer is running its docker container with a set of docker arguments that allows
it to run systemd as the init process. This makes it possible for you to test
that systemd services are installed and run properly.

If you want to test systemd services, you should make sure, the Docker image you're
using has systemd installed.

It also mounts the Docker socket inside the container so you can spin up containers.
The containers will be spun up on the host machine and not inside the Ansibeer container
though. This makes it impossible to test docker containers that mount local files into
the containers since Docker will look for the local files on the host rather than inside
the Ansibeer container. I haven't found a solution to this problem besides running Docker
in Docker using a privileged container and this is not really a path I'm likely to take.
