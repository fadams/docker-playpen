# glxgears

How to run GPU accelerated GUI applications in Docker containers.

This example explains how to use native Nvidia acceleration as well as using the VirtualBox virtual GPU for containers run from inside VirtualBox VMs.

## Introduction

Although most of the docker examples on the web tend to focus on server side applications it's perfectly possible to run GUI applications in docker containers. The "trick" is to mount the X11 socket and export the DISPLAY environment variable, that is to say in the *docker run* command include the following:

```
docker run --rm \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    <some GUI application>
```

That's not quite enough though, as the X11 authentication is likely to prevent connection from the container. The simplest way to resolve that is to allow access from localhost via:

```
xhost local:root
```

## Important Note on X11 Security

Enabling access to the X11 socket in this way opens a few [security holes](http://www.windowsecurity.com/whitepapers/unix_security/Securing_X_Windows.html), in particular it is possible for X11 applications in the container to capture X events (e.g. keyboard and mouse events), potentially from any window.

Using token authentication (by mounting the .Xauthority file provides finer grained control than server authentication, though is arguably no better than xhost local:root but certainly better than xhost +.

The simplest approach to token authentication is use the XAUTHORITY environment variable, but note that typically .Xauthority files are hostname specific so for this to work it is necessary to set the container's hostname and in general it's not great to run multiple containers with the same hostname (though docker will let you).

```
docker run --rm \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -h $(hostname) \
    -e XAUTHORITY=$XAUTHORITY \
    -v $XAUTHORITY:$XAUTHORITY \
    <some GUI application>
```

In order to avoid the need to set the container's hostname it is necessary to create an additional .Xauthority file with a wildcard hostname:

```
XAUTH=${XAUTHORITY:-$HOME/.Xauthority}
DOCKER_XAUTHORITY=${XAUTH}.docker
cp --preserve=all $XAUTH $DOCKER_XAUTHORITY
echo "ffff 0000  $(xauth nlist $DISPLAY | cut -d\  -f4-)" \
    | xauth -f $DOCKER_XAUTHORITY nmerge -
```

Then use the following to run the application:

```
docker run --rm \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e XAUTHORITY=$DOCKER_XAUTHORITY \
    -v $DOCKER_XAUTHORITY:$DOCKER_XAUTHORITY \
    <some GUI application>
```

Note that the .Xauthority is recreated with a different cookie every time the X Session starts so it is necessary to recreate the wildcarded .Xauthority then too. 


If full isolation/sandboxing is required it is necessary to bundle an X Server in the docker image, rendering to [Xvfb](https://en.wikipedia.org/wiki/Xvfb) (X11 Virtual Frame Buffer) then export the captured Frame Buffer via something like [Xpra](http://xpra.org/) or [VNC](https://en.wikipedia.org/wiki/Virtual_Network_Computing). This approach offers excellent application isolation, but requires many extra packages to be installed in the application image plus additional client software to render the display. More details on fully sandboxed approach TBD.

## Nvidia GPU Acceleration

In an *ideal world* the following Dockerfile should be enough to package a minimal OpenGL application such as glxgears:

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

using something like the following to run it, as described in the introduction:

```
docker run --rm \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    glxgears
```

Unfortunately the world is not ideal, and if you have Nvidia hardware you are likely to see something like:

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

Fortunately Nvidia have been working on a [Docker plugin](https://github.com/NVIDIA/nvidia-docker) that makes it *relatively* straightforward to leverage the power of GPU acceleration.

Note that the nvidia-docker Quick Start instructions are pretty good, but in my case I ran into a few issues. The first was that the nvidia-plugin requires nvidia-modprobe, which is available in some Linux repos, but in my case I ended up building it from [source](https://github.com/NVIDIA/nvidia-modprobe) and installing it. The second issue that I ran into was that the Ubuntu instructions:

```
# Install nvidia-docker and nvidia-docker-plugin
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
```

didn't set up the upstart configuration correctly for me, so the nvidia-docker-plugin didn't start up automatically on reboot. However, as I was able to manually start nvidia-docker via

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

With nvidia-docker-plugin running all that is required is to use **nvidia-docker run** insead of **docker run** when launching containers, that is to say:

```
nvidia-docker run --rm \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    glxgears
```

One additional thing that I discovered was that for some reason if a container needs *--net host* adding that flag will cause issues with OpenGL/WebGL, this can be resolved by adding *--device=/dev/nvidia-modeset* to the nvidia-docker run command (see https://github.com/NVIDIA/nvidia-docker/issues/421), so the final command becomes:

```
nvidia-docker run --rm \
    --device=/dev/nvidia-modeset \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    glxgears
```

Unfortunately, in addition to the host-side tweaks described above it is necessary to make a few additions to application Dockerfiles in order to launch with nvidia-docker.

The following Dockerfile additions are likely to be required by all Dockerfiles that require Nvidia acceleration. The LABEL is used by nvidia-docker run to decide if the driver volume and the device files are required and things won't work correctly if it's not in place, unfortunately that important piece of information isn't too obvious from the documentation as it's slightly hidden away [here](https://github.com/NVIDIA/nvidia-docker/wiki/Image-inspection#nvidia-docker).

```
LABEL com.nvidia.volumes.needed="nvidia_driver"
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}
```

Alternatively the LD_LIBRARY_PATH could be set via *-e* or *--env* in the docker run command, which is probably better than hard-coding it in the container.

Some other applications might require one or both of the following additions to the Dockerfile:

```
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
LABEL com.nvidia.cuda.version="7.5"
```

## VirtualBox Guest Additions Virtual GPU Acceleration

The approach for enabling acceleration within containers that are running on VirtualBox guest machines using VirtualBox Guest Additions is *somewhat* similar to that needed for Nvidia, though the detail is rather different.

The basic gist is that it is necessary to ensure that the Guest Additions libGL shared library is used *in preference* to the one shipped with the container's OpenGL and that a bunch of VirtualBox shared libraries are available for the VirtualBox libGL to use.

The files that seem to be required are:

```
/var/lib/VBoxGuestAdditions/lib/libGL.so.1
/usr/lib/x86_64-linux-gnu/VBoxEGL.so
/usr/lib/x86_64-linux-gnu/VBoxOGL.so
/usr/lib/x86_64-linux-gnu/VBoxOGLerrorspu.so
/usr/lib/x86_64-linux-gnu/VBoxOGLpassthroughspu.so
/usr/lib/x86_64-linux-gnu/VBoxOGLarrayspu.so
/usr/lib/x86_64-linux-gnu/VBoxOGLfeedbackspu.so
/usr/lib/x86_64-linux-gnu/VBoxOGLcrutil.so
/usr/lib/x86_64-linux-gnu/VBoxOGLpackspu.so
/usr/lib/x86_64-linux-gnu/libXcomposite.so.1
```

Which may be mounted as volumes, noting that libGL.so.1 should be mounted in the container at /usr/lib/x86_64-linux-gnu rather than /var/lib/VBoxGuestAdditions/lib.

It is also necessary to ensure that /dev/vboxuser is visible to the container via *--device=/dev/vboxuser*

## Open Source Mesa Drivers GPU Acceleration

In order to use the Open Source Mesa Drivers from a container the easiest thing to do is to include the *libgl1-mesa-dri* package in the container.

It is also necessary to ensure that /dev/dri is visible to the container via *--device=/dev/dri*. Note that if you forget to do this it's likely that it will still *appear* to work, but it would in fact be using the **software** renderer not the GPU.

## In Conclusion

For glxgears the final Dockerfile is therefore:

```
FROM debian:stretch-slim

# nvidia-docker hooks
LABEL com.nvidia.volumes.needed="nvidia_driver"

# Install glxgears
RUN apt-get update && \
    # Add the packages used
    apt-get install -y --no-install-recommends \
	mesa-utils libgl1-mesa-dri && \
	rm -rf /var/lib/apt/lists/*

ENV LIBGL_DEBUG verbose

ENTRYPOINT ["glxgears"]
```

and the script to run it on either an Nvidia host, a host using the Open Source Mesa drivers or a VirtualBox guest VM is:

```
if test -c "/dev/nvidia-modeset"; then
    # Nvidia GPU
    DOCKER_COMMAND=nvidia-docker
    GPU_FLAGS="--device=/dev/nvidia-modeset -e LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}"
else
    DOCKER_COMMAND=docker
    if test -d "/var/lib/VBoxGuestAdditions"; then
        # VirtualBox GPU
        VBOXPATH=/usr/lib/x86_64-linux-gnu
        GPU_FLAGS="--device=/dev/vboxuser -v /var/lib/VBoxGuestAdditions/lib/libGL.so.1:$VBOXPATH/libGL.so.1"
        for f in $VBOXPATH/VBox*.so $VBOXPATH/libXcomposite.so.1
        do
            GPU_FLAGS="${GPU_FLAGS} -v $f:$f"
        done
    else
        # Default to Open Source Mesa GPU
        GPU_FLAGS="--device=/dev/dri"
    fi
fi

# Create .Xauthority.docker file with wildcarded hostname.
XAUTH=${XAUTHORITY:-$HOME/.Xauthority}
DOCKER_XAUTHORITY=${XAUTH}.docker
cp --preserve=all $XAUTH $DOCKER_XAUTHORITY
echo "ffff 0000  $(xauth nlist $DISPLAY | cut -d\  -f4-)" \
    | xauth -f $DOCKER_XAUTHORITY nmerge -

$DOCKER_COMMAND run --rm \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e XAUTHORITY=$DOCKER_XAUTHORITY \
    -v $DOCKER_XAUTHORITY:$DOCKER_XAUTHORITY \
    $GPU_FLAGS \
    glxgears
```

