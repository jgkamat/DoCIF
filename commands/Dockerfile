# You can change this to any version of ubuntu with little consequence
FROM ubuntu:16.04
MAINTAINER Jay Kamat jaygkamat@gmail.com

# This dockerimage will serve as a 'static' base for using the DoCIF project

# Setup apt to be happy with no console input
ENV DEBIAN_FRONTEND noninteractive

# Use UTF-8, fixes some hard to debug issues
# This is not workin on cirlceci's current setup. Will reenable once it's working again
# RUN locale-gen en_US.UTF-8
# ENV LANG en_US.UTF-8

# setup apt tools and other goodies we want
RUN apt-get update --fix-missing && apt-get -y install curl git bsdmainutils sudo && apt-get clean

# Link up to where DoCIF expects us to go.
# See ${DOCKER_PROJECT_ROOT} for more info
RUN mkdir -p /root/project
WORKDIR /root/project

# This image is not meant to be run directly, it has not been compiled yet!
# In addition, it does not contain any source code, only dependencies
