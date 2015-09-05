# DoCIF
Docker Continuous Integration Framework - A framework for easily testing your project with Docker!

#WARNING: THIS PROJECT IS STILL UNDER HEAVY DEVELOPMENT, MOST FEATURES ARE INCOMPLETE OR NON-FUNCTIONAL. DO NOT USE THIS IN ANY IMPORTANT ENVIRONMENT UNTIL THE FIRST STABLE VERSION OF DoCIF IS RELEASED.

DoCIF is a framework making it easy to test your project with Docker. You only need to configure DoCIF, and DoCIF will handle building docker images, caching using the docker hub, and github status updates!

DoCIF was originally made for [RoboJackets/robocup-software](https://www.github.com/robojackets/robocup-software), but it has been generalized to work on any git repostiory.


## Requirements
* Git managed project and `git 2.0+`
* [Docker](https://www.docker.com) installed on your system or continuous integration
* Bash on a POSIX (preferrably GNU) system.

## Setup
Setup of DoCIF is designed to be easy, assuming you know how to set up your project on a linux machine!

1. Set up a config.docif file in the root of your repository. See [samples](./sample/sample-config.docif) for one. You should be able to copy paste this into your project and tweak the variables to your liking. While most options are
optional, some must be changed.
2. Add DoCIF as a submodule to your repository.
3. Add a circle.yml file to the base of your repository. A sample one, which you can copy paste if you don't already have a circle config, can be found in the samples directory. If you already have a circle config, you may want to merge them manually, unless you want to use only DoCIF.

## License
DoCIF is licensed under the GNU LGPLv3. In an incomplete summary, this means you can use DoCIF with any project (even nonfree ones :cry:), but if you mod DoCIF itself, you must license the derivative work under the LGPLv3 or the GPLv3. See the included LICENSE file for details.
