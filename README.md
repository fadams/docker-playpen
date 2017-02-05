# docker-playpen
Playpen repository for docker experiments.

The subdirectories contain some examples for building different types of containers, for example [hello-world](hello-world) illustrates building a fairly minimal (1.8K) image by building a static executable, more interestingly is also illustrates how to do a *fully dockerised build* where the **entire build toolchain and executable** are built inside a docker container.

## Portainer
[Portainer](http://portainer.io/) is a simple management UI for docker, the source is [here](https://github.com/portainer/portainer) but it is itself dockerised and cmay be installed and by simply running the following command:
````
docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
````

Running the above command pulls [portainer/portainer](https://hub.docker.com/r/portainer/portainer/) from [docker hub](https://hub.docker.com/explore/), installs the image, then fires up a container in detached mode (**-d**) and binds the container port 9000 to host port 9000 (**-p 9000:9000**). The **-v /var/run/docker.sock:/var/run/docker.sock** switch provides the container with access to the docker socket to allow processes running in that container to extract information about other containers.

Portainer is a really useful and intuitive way to reduce the *barrier to entry* of docker, it's especially useful for helping to tidy up 'orphaned' containers and images which are fairly easily missed when using the basic docker CLI.

Full Portainer documentatiuon may be found [here](https://portainer.readthedocs.io/en/stable/).

## Cheat Sheet
Download, install and run the official hello-world image
````
docker run hello-world
````

By default a container’s file system persists even after the container exits. This makes debugging a lot easier (since you can inspect the final state) and you retain all your data by default. But if you are running short-term foreground processes, these container file systems can really pile up. If instead you’d like docker to automatically clean up the container and remove the file system when the container exits, you can add the **--rm** flag
````
docker run --rm hello-world
````

List all containers
````
docker ps -a
````

List ID's of all containers
````
docker ps -a -q
````

List all images
````
docker images
````

List ID's of all images
````
docker images -q
````

Delete image (the following are aliases, **-f** means force)
````
docker image rm -f <name or ID>
docker rmi -f <name or ID>
````

Delete all local containers
````
docker rm $(docker ps -a -q)
````

Delete all local images
````
docker image rm $(docker images -q)
````

Show docker disk usage
````
docker system df -v
````

Run specified image interactively in a container **-i** Keeps STDIN open even if not attached **-t** allocates a pseudo-tty
````
docker run --rm -it debian:jessie-slim
````

Run specified image interactively in a container mounting current working directory
````
docker run --rm -it -v $PWD:/build debian:jessie-slim
````

## Useful Links
Docker Open Source site: https://www.docker.com/technologies/overview

Docker documentation: https://docs.docker.com/

Get Docker for Ubuntu: https://docs.docker.com/engine/installation/linux/ubuntu/

Build your own image: https://docs.docker.com/engine/getstarted/step_four/

Swarm mode overview: https://docs.docker.com/engine/swarm/

http://www.midvision.com/blog/10-open-source-docker-tools-you-should-be-using

https://www.iron.io/microcontainers-tiny-portable-containers/

https://opensolitude.com/2015/05/13/docker-images-should-be-small.html

https://github.com/NVIDIA/nvidia-docker







