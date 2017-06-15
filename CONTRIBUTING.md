# Contributing to Sirko Engine

Nice to see you here! :bowtie:

This guide is aimed to help you to start contributing to Sirko Engine. If you miss something, please, don't hesitate to open an issue or a pull request, we will improve this guide. :wink:

Currently, the project is at a very early stage. The final idea isn't fully defined, but the rough idea is to build the project which can increase an engagement rate on sites by incorporating [Progressive Web Apps'](https://developers.google.com/web/progressive-web-apps/) features. Eventually, it should improve the conversion rate of a site.

If you have any thoughts about models, technologies, solutions, features, please, open an issue. Now it is crucial to drive the project towards needs of people who might be interested in this kind of the project.

## Table of contents

- [Development environment](#development-environment)
- [Testing](#testing)
- [Style guide](#style-guide)
- [Creating a PR](#creating-a-pr)
- [Building a release](#building-a-release)

## Development environment

### Dependencies

 - [Elixir](http://elixir-lang.org/install.html) 1.4.*
 - [Neo4j](https://neo4j.com/download/) 3.*
 - [Npm](https://npmjs.com)

To avoid any issues with installing Neo4j (we don't say it is hard :blush:), we recommend using [Docker](https://www.docker.com/). Execute the following command to install Neo4j:

```
$ sudo docker run --name neo4j-db -d -e NEO4J_AUTH=none --restart always -p 7687:7687 -p 7474:7474 neo4j:3.1
```

The web interface of Neo4j is accessible on [http://localhost:7474](http://localhost:7474).

### Setup

1. Clone your fork.
2. Install dependencies:

    ```
    $ mix deps.get
    $ npm install
    ```

3. Set a url to your site:

    ```
    # .profile
    export SIRKO_CLIENT_URL="http://localhost:3000"
    ```

4. Launch the app:

    ```
    $ iex -S mix
    ```

5. [Integrate](https://github.com/sirko-io/engine#client-integration) the sirko client into a site you want to use for testing.

**Note:** If you don't have a site for checking your changes, you can clone [this demo site](https://github.com/sirko-io/demo) and locally set it up.

## Testing

The app uses [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) as a testing framework.
To launch tests, execute the following command:

```
$ mix test
```

**Each change must be covered with a test.**

The project is integrated with [TravisCI](https://travis-ci.org). Before creating a PR, please be sure your changes pass tests there.

Neo4j doesn't support multiple databases. So, to keep the test environment isolated from the development environment, you can launch a separate Neo4j instance via Docker:

```
$ sudo docker run --name neo4j-test-db -d -e NEO4J_AUTH=none --restart always -p 7688:7687 -p 7475:7474 neo4j:3.1
```

## Style guide

The project doesn't have any specific requirements to the code. To be consistent, a [Credo](https://github.com/rrrene/credo) library is integrated into the project.

```
$ mix credo
```

Please, take your time and learn how to use this tool. It won't require more than 10 mins.

Currently, new changes shouldn't bring inconsistency issues and warnings. Later we might be more strict.

## Creating a PR

If you've never contributed to an open-source project, this [tutorial](https://egghead.io/courses/how-to-contribute-to-an-open-source-project-on-github) will help you.

Before submitting a PR, make sure the PR meets following requirements:

- no failed tests on TravisCI
- squashed commits into one
- the first line of the commit message is limited to 72 characters
- the reference to an issue on GitHub is added after the first line
- the commit message explains an issue the PR is aimed to solve and an actual solution to that issue
- the brief description of the change is added to the [changelog](https://github.com/sirko-io/engine/blob/master/CHANGELOG.md)
- if it is a PR looking for early feedback, it is prefixed with `[WIP]`

## Building a release

To release the engine, a [distilery](https://github.com/bitwalker/distillery) tool gets used. It packages an elixir application, so it can be launched anywhere without installing Elixir and Erlang. The built package contains all dependencies. As elixir applications cannot be configured via environment variables after compilation, a [conform](https://github.com/bitwalker/conform) library is used to configure the engine in runtime.

To build a new release, follow the following steps:

1. Make sure the version of the engine in `Sirko.Mixfile` is valid.
2. Make sure the production config `config/sirko.conf` is up to date.
3. Make sure the `package.json` contains a valid version of the sirko client.
4. Build the release:

    ```
    $ MIX_ENV=prod mix release --env=prod
    ```

5. Prepare the release on the GitHub and upload `_build/prod/rel/sirko/releases/x.x.x/sirko.tar.gz`.
6. Release the engine as a [docker image](https://github.com/sirko-io/docker).
