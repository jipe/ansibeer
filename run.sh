#!/bin/bash
function usage {
  error=$1

  if [ -n "$error" ]
  then
    echo "ERROR: $error"
    exit_code=1
  else
    exit_code=0
  fi

  echo "$0 [options] <playbook>"
  echo
  echo "Build and run a container and run the Ansible playbook inside of it"
  echo
  echo "Options:"
  echo "  -i, --image : Specify the base Docker image to use"
  echo

  exit $exit_code
}

ansible_home=${ANSIBLE_HOME:-$HOME/ansible}
image=debian:stretch

echo "Ansible home is '$ansible_home'"

for arg
do
  if [ -n "$expect" ]
  then
    case $expect in
      image)
        image=$arg
        ;;
      *)
        usage "Uncaught expected value '$arg' for '$expect'"
        exit 1
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
      -i|--image)
        expect=image
        ;;
      --image=*)
        image=${arg##--image=}
        ;;
      -h|--help)
        usage
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

if [ -f dockerfiles/$image ]
then
  new_image=ansible-test-$(echo $image | tr '/:' '--'):${playbook##*/}
  docker pull $image
  docker build -t $new_image -f dockerfiles/$image .

  if [ ! "$?" == "0" ]
  then
    docker rm $(docker ps -a --format '{{.Names}} {{.Status}}' | grep second | cut -d' ' -f1)
    exit 1
  fi

  image=$new_image
fi

docker run -ti -d --rm \
                  --name ansible-test \
                  -v $ansible_home:/etc/ansible:ro \
                  -v $PWD/$playbook:/playbook:rw \
                  $image bash

if [ ! "$?" == "0" ]
then
  echo "Could not run container"
  exit 1
fi

docker exec -ti ansible-test ansible-playbook --connection=local -i 'localhost,' /playbook
docker exec -ti ansible-test bash
docker stop ansible-test
