#!/bin/bash

# set -e exits as soon as any line in the bash script fails.
# set -x prints command that is going to be executed with a little plus.
set -e

echo "Dockerised Build of hello-world"

# Find the absolute path of the executing script and cd to it
cd $(dirname "$(readlink -f "$BASH_SOURCE")")

# Build the entire build toolchain into the image hello-world:build
# The creates an image based on debian:jessie-slim and installs gcc, cmake etc.
# The CMakeLists.txt performs the equivalent of
# gcc -Wall -Os -static -nostartfiles -fno-asynchronous-unwind-tables -s -o hello hello.c
docker build -f Dockerfile.build -t hello-world:build .

# Remove any previous version of the executable
rm -rf ./hello

# Run hello-world:build in a container find the executable and extract it.
: <<'end_comment_block'
find \( -name hello -or -name hello.txt \)
finds files named hello but it prints the results separated by newlines, e.g.
./hello
./build/hello

find \( -name hello -or -name hello.txt \) -print0
finds files named hello but prints the full file name on the standard output,
followed by a null character (instead of the newline character that -print uses).
This allows file names that contain newlines or other types of white space to be
correctly interpreted by programs that process the find output.

xargs builds and execute command lines from standard input so | xargs pipes the
output of find to xargs which subsequently runs tar --create
end_comment_block

docker run --rm hello-world:build sh -c 'find \( -name hello -maxdepth 1 \) -print0 | xargs -0 tar --create' | tar --extract --verbose

# Build the executable into the image hello-world:latest
docker build -t hello-world .

# Remove the executable now that the docker image has been built
rm -rf ./hello

