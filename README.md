# DoCIF [![Build Status](https://circleci.com/gh/jgkamat/DoCIF.svg?&style=svg)](https://circleci.com/gh/jgkamat/DoCIF)

Docker Continuous Integration Framework - A framework for easily testing your project with Docker!

### DoCIF is in Release Candidate. Please help out to test for bugs before the first release!

DoCIF is a framework making it easy to test your project with Docker. You only need to configure DoCIF, and DoCIF will handle building docker images, caching using the docker hub, and github status updates!

DoCIF was originally made for [RoboJackets/robocup-software](https://www.github.com/robojackets/robocup-software), but it has been generalized to work on any git repostiory.


## Requirements
* Git managed project and `git 2.0+`
* [Docker](https://www.docker.com) installed on your system or continuous integration
* Bash 4+ on a POSIX (preferrably GNU) system.
* CircleCi Continuous Integration. The features included in DoCIF take adavantage of its features, such as artifact deployment, and caching.

## Features
* Run your CI Tests in Docker
* Use Docker to cache your builds to make them run faster (if you have lots of dependencies)
* Use The GH Status Token API To let you know which one of your tests failed
  * Easily see what went wrong in each test with automatic deployment of output files and a link in your status message.
* Run your tests in the environment you want, not the environment someone provides you!
  * Ability to supply your own dockerfile to do this. Be careful though, you could break some things.
  * [DoCIF's tests are run using DoCIF](https://github.com/jgkamat/DoCIF/pull/4). Yes it was hard. It's also a good example of the end result from your point of view.

## Documentation

Below, you will find a simple setup guide, buf if you need additional clarification or help with advanced usage, check out the [docs folder of this repo](./doc/index.org)

## Setup
Setup of DoCIF is designed to be easy, assuming you know how to set up your project on a linux machine!

1. Set up a config.docif file in the root of your repository. See [samples](./sample/sample_config.docif) for one. You should be able to copy paste this into your project and tweak the variables to your liking. While most options are
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

## Advanced Features

DoCIF has support for many nice features such as individual GitHub status icons and caching basimages.

#### Status Icons

Status Entries require a few extra variables to be set properly, as well as a user with a GH Status API Token. Look in your config.docif to see some examples of these.

1. Set `GITHUB_REPO` to your repo on github. For example, you would turn https://github.com/alda-lang/alda into `alda-lang/alda`.
2. Set environmental variables for your GH Status token, username, and email via the circleci web interface (secure) or your circle.yml (insecure). Then place the NAMES of these env variables in `GH_STATUS_TOKEN_VAR`, `GH_USER_VAR`, and `GH_EMAIL_VAR`.
3. Add multiple `TEST_COMMANDS` to see them come up as individual status tokens.

Once this is done, the logs of each test command can be viewed by clicking 'details' on any of these outputs.

You can debug issues by running the build on circleCi with ssh, and running `bash -x ./path/to/DoCIF/util/maketest.sh --pending` and looking for the output of the curl commands. Those curl commands are docif trying to set status tokens.

#### Caching Via DockerHub

DoCIF can create a 'baseimage' for you and automatically rebuild it when certain files (setup/dependency files) change.

1. Create an account on the docker hub, and create a normal (not automated build) repository to use as a baseimage push location.
2. Place your docker user, email, and password into circleci (secure) or circle.yml (insecure). Then set `DOCKER_PASSWORD_VAR`, `DOCKER_EMAIL_VAR`, and `DOCKER_USER_VAR` to the VARIABLE NAMES of the respective credentials.
3. Add file names as elements to `SETUP_SHA_FILES` to force a rebuild when they change.

## Debugging a DoCIF Error

DoCIF has a bunch of error messages, but they are hard to see at times. Open up the raw output from circleci and search for `[WARN]` and `[ERR]`. All DoCIF error messages will have those headers.

Check to make sure your credentials work

If all else fails, ssh into the circleci node, run `bash -x ./path/to/DoCIF/command` and find where DoCIF went wrong.

If you find a problem within DoCIF itself or want more features, simply submit an issue to this repostiory! :smile:

## License
DoCIF is licensed under the GNU LGPLv3. In an incomplete summary, this means you can use DoCIF with any project (even nonfree ones :cry:), but if you mod DoCIF itself, you must license the derivative work under the LGPLv3 or the GPLv3. See the included LICENSE file for details.
