#!/bin/bash
function usage {
  error=$1

  if [ -n "$error" ]
  then
    echo "ERROR: $error"
    echo
    exit_code=1
  else
    exit_code=0
  fi

  echo "$0 [options] <playbook>"
  echo
  echo "Build and run a container and run the Ansible playbook inside of it"
  echo
  echo "Options:"
  echo "  -a, --ansible-home : Specify location of Ansible repository"
  echo "                       Default: ANSIBLE_HOME env var or $default_ansible_home"
  echo "  -f,        --facts : Show container facts"
  echo "  -i,        --image : Specify the base Docker image to use"
  echo "                       Default: IMAGE env var or $default_image"
  echo

  exit $exit_code
}

default_ansible_home=$HOME/ansible
ansible_home=${ANSIBLE_HOME:-$default_ansible_home}
default_image=debian:stretch

for arg
do
  if [ -n "$expect" ]
  then
    case $expect in
      default_image)
        default_image=$arg
        ;;
      image)
        image=$arg
        ;;
      -*)
        usage "Value for '$expect' seems to be a flag"
        ;;
      *)
        usage "Uncaught expected value '$arg' for '$expect'"
        ;;
    esac
    unset expect
  else
    case $arg in
      -a|--ansible-home)
        expect=ansible_home
        ;;
      --ansible-home=*)
        ansible_home=${arg##--ansible-home=}
        ;;
      --default-image)
        expect=default_image
        ;;
      --default-image=*)
        default_image=${arg##--default-image=}
        ;;
      -f|--facts)
        show_facts=true
        ;;
      -h|--help)
        usage
        ;;
      -i|--image)
        expect=image
        ;;
      --image=*)
        image=${arg##--image=}
        ;;
      *)
        if [ -n "$playbook" ]
        then
          usage "extra argument '$arg'"
        fi
        playbook=$arg
        ;;
    esac
  fi
done

if [ -z "$image" ]
then
  image=${IMAGE:-$default_image}
fi

if [ -f dockerfiles/$image ]
then
  new_image=ansibeer-$(echo $image | tr '/:' '--'):${playbook##*/}
  docker pull $image
  docker build -t $new_image -f dockerfiles/$image .

  if [ ! "$?" == "0" ]
  then
    docker rm $(docker ps -a --format '{{.Names}} {{.Status}}' | grep second | cut -d' ' -f1)
    exit 1
  fi

  image=$new_image
fi

if [ -n "$(echo $playbook | cut -d'/' -f1)" ]
then
  playbook=$PWD/$playbook
fi

docker run -ti -d --rm \
                  --name ansibeer \
                  -v $ansible_home:/etc/ansible:ro \
                  -v $playbook:/playbook:rw \
                  $image bash

if [ ! "$?" == "0" ]
then
  echo "Could not run container"
  exit 1
fi

if [ -n "$show_facts" ]
then
  docker exec -ti ansibeer ansible localhost --connection=local -m setup
fi

echo "Checking Ansible syntax"

docker exec -ti ansibeer ansible-playbook --connection=local -i 'localhost,' --syntax-check /playbook

if [ "$?" == "0" ]
then
  echo "Syntax check complete"
else
  echo "Syntax check failed"
  exit 1
fi

echo "Applying playbook"

docker exec -ti ansibeer ansible-playbook --connection=local -i 'localhost,' /playbook
exit_code=$?

if [ -t 1 ]
then
  docker exec -ti ansibeer bash
fi

docker stop ansibeer
exit $exit_code
