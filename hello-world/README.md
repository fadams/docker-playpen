# hello-world

From tutorial:
https://docs.docker.com/engine/userguide/eng-image/baseimages/

The [CMakeLists.txt](CMakeLists.txt) does the eqivalent of the following
````
gcc -Wall -Os -static -nostartfiles -fno-asynchronous-unwind-tables -s -o hello hello.c
strip -R .comment -s hello
````

There are two approaches available for building:

The first is to build natively on a Linux host:
````
mkdir build
cd build
cmake ..
make
cd ..
docker build -t hello-world .
rm -rf build ./hello
````

The second is to do a dockerised build where the **entire build toolchain and
executable** are built inside a docker container.
````
./dockerised-build.sh
````

Run hello-world in a container:
````
docker run --rm hello-world
````
