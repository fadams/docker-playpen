# Docker Pulseaudio

How to run pulseaudio client applications in Docker containers.

## Introduction

Most of the docker examples on the web are resolutely silent, but it's often desirable to be able to run audio processing applications in containers and most Linux audio applications these days tend to use pulseaudio, so here's what I've discovered to get pulseaudio applications up and running in containers.

## Mount Pulseaudio Socket Path and Set PULSE_SERVER Variable.

The most important things needed to enable pulseaudio support are to pass the pulseaudio socket path and the PULSE_SERVER environment variable as follows:

```
docker run --rm \
    -e PULSE_SERVER=unix:/run/user/$(id -u)/pulse/native \
    -v /run/user/$(id -u)/pulse:/run/user/$(id -u)/pulse \
    <pulseaudio-application>
```

however that won't work correctly as containers default to a root user with a uid of 0

## Pass the User's uid to the Container

Simply using docker run's -u option, e.g. *-u $(id -u)*, seems to be enough to connect correctly.

For a simple example using pacat to play random noise the Dockerfile is therefore:

```
FROM debian:stretch-slim

# Tell debconf to run in non-interactive mode
ENV DEBIAN_FRONTEND noninteractive

RUN \
    # Ensure repository information is up to date
    apt-get update && \

    # Add the required packages
    apt-get install -y --no-install-recommends \
    pulseaudio-utils && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /src/*.deb

# run
CMD ["pacat", "-vvvv", "/dev/urandom"]
```

and the script to run it is:

```
#!/bin/bash

docker run --rm \
    -e PULSE_SERVER=unix:/run/user/$(id -u)/pulse/native \
    -v /run/user/$(id -u)/pulse:/run/user/$(id -u)/pulse \
    -u $(id -u) \
    pulse-example
```




