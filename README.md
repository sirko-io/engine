# Sirko Engine

[![Build Status](https://travis-ci.org/dnesteryuk/sirko-engine.svg?branch=master)](https://travis-ci.org/dnesteryuk/sirko-engine)

A simple engine to track users' navigation on a site and predict a next page which most likely will be visited by the current user. As soon as we are able to predict the next page, we can prerender that page in order to provide better experience (an instant transition in some cases) to the user.

A full description of the prerendering idea can be found in [this article](http://nesteryuk.info/2016/09/27/prerendering-pages-in-browsers.html).

## Development

### Requirements

 - [Elixir](http://elixir-lang.org/install.html) 1.3.*
 - [Neo4j](https://neo4j.com/download/) 3.0.*

If you use [docker](https://www.docker.com/), execute the following command to install Neo4j:

```
$ sudo docker run --name neo4j-db -d --env NEO4J_AUTH=none --restart always --publish 7474:7474 neo4j:3.0.6
```

The web interface of Neo4j is accessible on [http://localhost:7474](http://localhost:7474).

### Setup

1. Clone your fork.
2. Install dependencies:

    ```
    $ mix deps.get
    ```

3. Launch the app:

    ```
    $ iex -S mix
    ```

  _Note:_ The [sirko client](https://github.com/dnesteryuk/sirko-client) has to be configured to send data to `http://localhost:4000`.

### Testing

The app uses [ExUnit](http://elixir-lang.org/docs/stable/ex_unit/ExUnit.html) as a testing framework.
Execute the following command to launch the tests:

```
$ mix test
```
