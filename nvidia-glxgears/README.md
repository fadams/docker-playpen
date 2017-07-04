# nvidia-glxgears

How to run Nvidia GPU accelerated GUI applications in Docker containers.

## Introduction

Although most of the docker examples on the web tend to focus on server side applications it's perfectly possible to run GUI applications in docker containers, the "trick" is to mount the X11 socket and export the DISPLAY environment variable, that is to say in the *docker run* command include the following:

```
-e DISPLAY=unix$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix
```

That's not quite enough though, as the X11 authentication is likely to prevent connection from the container. The simplest way to resolve that is to allow access from localhost via:

```
xhost local:root
```

## Important Note on X11 Security

Enabling access to the X11 socket in this way opens a few [security holes](http://www.windowsecurity.com/whitepapers/unix_security/Securing_X_Windows.html), in particular it is possible for X11 applications in the container to capture X events (e.g. keyboard and mouse events), potentially from any window.

Using token authentication (by mounting the .Xauthority file via something like -v $HOME/.Xauthority:/home/<app-user>/.Xauthority) provides finer grained control than server authentication, though is arguably no better than xhost local:root but certainly better than xhost +

If full isolation/sandboxing is required it is necessary to bundle an X Server in the docker image, rendering to [Xvfb](https://en.wikipedia.org/wiki/Xvfb) (X11 Virtual Frame Buffer) then export the captured Frame Buffer via something like [Xpra](http://xpra.org/) or [VNC](https://en.wikipedia.org/wiki/Virtual_Network_Computing). This approach offers excellent application isolation, but requires many extra packages to be installed in the application image plus additional client software to render the display. More details on fully sandboxed approach TBD.

## GPU Acceleration

In an ideal world, with a Dockerfile

```
FROM debian:stretch-slim

# Install glxgears
RUN apt-get update && \
    # Add the packages used
    apt-get install -y --no-install-recommends \
	mesa-utils && \
	rm -rf /var/lib/apt/lists/*

ENV LIBGL_DEBUG verbose

ENTRYPOINT ["glxgears"]
```

and doing something like

```
docker run --rm \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    glxgears
```

to run it would "just work", but unfortunately if you have Nvidia hardware you are likely to see something like:

```
libGL: screen 0 does not appear to be DRI2 capable
libGL: OpenDriver: trying /usr/lib/x86_64-linux-gnu/dri/tls/swrast_dri.so
libGL: OpenDriver: trying /usr/lib/x86_64-linux-gnu/dri/swrast_dri.so
libGL: dlopen /usr/lib/x86_64-linux-gnu/dri/swrast_dri.so failed (/usr/lib/x86_64-linux-gnu/dri/swrast_dri.so: cannot open shared object file: No such file or directory)
libGL: OpenDriver: trying ${ORIGIN}/dri/tls/swrast_dri.so
libGL: OpenDriver: trying ${ORIGIN}/dri/swrast_dri.so
libGL: dlopen ${ORIGIN}/dri/swrast_dri.so failed (${ORIGIN}/dri/swrast_dri.so: cannot open shared object file: No such file or directory)
libGL: OpenDriver: trying /usr/lib/dri/tls/swrast_dri.so
libGL: OpenDriver: trying /usr/lib/dri/swrast_dri.so
libGL: dlopen /usr/lib/dri/swrast_dri.so failed (/usr/lib/dri/swrast_dri.so: cannot open shared object file: No such file or directory)
libGL error: unable to load driver: swrast_dri.so
libGL error: failed to load driver: swrast
X Error of failed request:  BadValue (integer parameter out of range for operation)
  Major opcode of failed request:  154 (GLX)
  Minor opcode of failed request:  3 (X_GLXCreateContext)
  Value in failed request:  0x0
  Serial number of failed request:  35
  Current serial number in output stream:  37
```

Fortunately Nvidia have been working on a [Docker plugin](https://github.com/NVIDIA/nvidia-docker) that makes it relatively straightforward to leverage the power of GPU acceleration.

Note that the nvidia-docker Quick Start instructions are pretty good, but in my case I ran into a few issues. The first was that the nvidia-plugin requires nvidia-modprobe, which is available in some Linux repos, but in my case I ended up building it from [source](https://github.com/NVIDIA/nvidia-modprobe) and installing it. The second issue that I ran into was that the Ubuntu instructions

```
# Install nvidia-docker and nvidia-docker-plugin
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb

# Test nvidia-smi
nvidia-docker run --rm nvidia/cuda nvidia-smi
```

didn't set up the upstart configuration correctly for me, so the nvidia-docker-plugin didn't start up automatically. As I was able to start nvidia-docker via

```
sudo start nvidia-docker
```

I had a suspicion that the issue was due to some start up dependency, so I tried changing the "start on" line in /etc/init/nvidia-docker.conf from

```
start on (local-filesystems and net-device-up)
```

to

```
start on (local-filesystems and net-device-up and started docker)
```

which seems to have resolved the issue.


