# DoCIF
Docker Continuous Integration Framework - A framework for easily testing your project with Docker!

###DoCIF is in Release Candidate. Please help out to test for bugs before the first release!

DoCIF is a framework making it easy to test your project with Docker. You only need to configure DoCIF, and DoCIF will handle building docker images, caching using the docker hub, and github status updates!

DoCIF was originally made for [RoboJackets/robocup-software](https://www.github.com/robojackets/robocup-software), but it has been generalized to work on any git repostiory.


## Requirements
* Git managed project and `git 2.0+`
* [Docker](https://www.docker.com) installed on your system or continuous integration
* Bash on a POSIX (preferrably GNU) system.
* CircleCi Continuous Integration. The features included in DoCIF take adavantage of it's features, such as artifact deployment, and caching.

## Setup
Setup of DoCIF is designed to be easy, assuming you know how to set up your project on a linux machine!

1. Set up a config.docif file in the root of your repository. See [samples](./sample/sample-config.docif) for one. You should be able to copy paste this into your project and tweak the variables to your liking. While most options are
optional, some must be changed.
2. Add DoCIF as a submodule to your repository.
3. Add the circle.yml file to the base of your repository. A sample one, which you can copy paste if you don't already have a circle config, can be found [in the samples directory](./sample/circle.yml). If you already have a circle config, you may want to merge them manually, unless you want to use only DoCIF.
4. Set CircleCi to use your Environment Variable Secrets in the online settings, and set parallelism to 1x (allows for 4 concurrent builds).

## Easy Setup

1. `git submodule add https://github.com/jgkamat/DoCIF.git` in project root
2. `cp DoCIF/sample/sample_config.docif .`
    1. Edit sample_config.docif to use settings specific to your project. Take a look at every setting with a `@REQUIRED` label
3. `cp DoCIF/sample/config.yml ` This will overwrite your existing circle.yml
4. Add the secrets you told config.docif about into the circleci web interface to use all features.
5. Enjoy!

## License
DoCIF is licensed under the GNU LGPLv3. In an incomplete summary, this means you can use DoCIF with any project (even nonfree ones :cry:), but if you mod DoCIF itself, you must license the derivative work under the LGPLv3 or the GPLv3. See the included LICENSE file for details.
