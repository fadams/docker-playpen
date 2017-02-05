#
# Copyright 2016 Fraser Adams
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

cmake_minimum_required(VERSION 2.6)

# Set project to C only (suppresses CMake C++ compiler detection)
project(hello-world C)

# Set the build type
if(CMAKE_BUILD_TYPE)
    # Use specified build type.
else()
    # If CMAKE_BUILD_TYPE not specified then default to Release.
    set(CMAKE_BUILD_TYPE MinSizeRel)
    #set(CMAKE_BUILD_TYPE Release)
    #set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

message(STATUS "Build type is ${CMAKE_BUILD_TYPE}")

# Suppress -rdynamic (see below)
# https://www.mail-archive.com/cmake@cmake.org/msg08837.html
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS)

set(COMPILE_WARNING_FLAGS "-Werror -Wall -pedantic-errors")
#set(COMPILE_PLATFORM_FLAGS "-pthread")
set(COMPILE_PLATFORM_FLAGS "-std=c99 -static -nostartfiles -fno-asynchronous-unwind-tables -s")


set(executables
    hello.c
    )

# Create executable_targets variable from list of executables with .c removed.
string(REPLACE ".c" "" executable_targets "${executables}")

# Create executable_targets_fullpath variable from executable_targets by
# prepending ${PROJECT_SOURCE_DIR}/ to each target.
string(REGEX REPLACE "([^;]+)" "${PROJECT_SOURCE_DIR}/\\1" executable_targets_fullpath "${executable_targets}")

set_source_files_properties(
    ${executables}
    PROPERTIES
    COMPILE_FLAGS "${COMPILE_WARNING_FLAGS} ${COMPILE_PLATFORM_FLAGS}"
    )

# Define the targets for compiling the executables
foreach(sourcefile ${executables})
    # Simple string replace, to cut off .cpp.
    string(REPLACE ".c" "" executable ${sourcefile})
    add_executable(${executable} ${sourcefile})
    #target_link_libraries(${executable} pfac ${OpenCL_LIBRARY})
    add_custom_command(
        TARGET ${executable}
        COMMAND strip -R .comment -s ${executable}
        COMMENT "Stripping ${executable}"
    )

    add_custom_command(
        TARGET ${executable}
        COMMAND ${CMAKE_COMMAND}
                -E copy
                ${CMAKE_CURRENT_BINARY_DIR}/${executable}
                ${PROJECT_SOURCE_DIR}/${executable}
        COMMENT "Copying ${executable} to ${PROJECT_SOURCE_DIR}"
    )
endforeach(sourcefile ${executables})

set_property(
    DIRECTORY APPEND PROPERTY
    ADDITIONAL_MAKE_CLEAN_FILES ${executable_targets_fullpath}
)

set_target_properties(
    ${executable_targets}
    PROPERTIES
    LINK_FLAGS "${COMPILE_PLATFORM_FLAGS}"
    )


# The docker target yses Dockerfile to build thestatic executable into a
# docker image called hello-world.
add_custom_target(
    docker
    COMMAND docker build -t hello-world ${PROJECT_SOURCE_DIR}
    COMMENT "Building docker image"
)


