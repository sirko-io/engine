# Sirko Engine

[![Build Status](https://travis-ci.org/dnesteryuk/sirko-engine.svg?branch=master)](https://travis-ci.org/dnesteryuk/sirko-engine)

It is a simple engine to track users' navigation on a site and predict the next page which most likely will be visited by the current user.
As soon as we are able to predict the next page, we can prerender that page in order to provide better experience (an instant transition in some cases) to the user.

A full description of the prerendering idea can be found in [this article](http://nesteryuk.info/2016/09/27/prerendering-pages-in-browsers.html).
How it works in the Chrome you can read [here](https://www.chromium.org/developers/design-documents/prerender).

[Try demo](http://demo.sirko.io)

## Usage

Currently, the easiest way to install the application is to use a [docker image](https://github.com/dnesteryuk/sirko-docker). Although, if you are familiar with the Elixir language, you can compile the application and setup your server.

## Development

### Dependencies

 - [Elixir](http://elixir-lang.org/install.html) 1.3.* or 1.4.*
 - [Neo4j](https://neo4j.com/download/) 3.*

If you use [docker](https://www.docker.com/), execute the following command to install Neo4j:

```
$ sudo docker run --name neo4j-db -d -e NEO4J_AUTH=none --restart always -p 7474:7474 neo4j:3.1
```

The web interface of Neo4j is accessible on [http://localhost:7474](http://localhost:7474).

### Setup

1. Clone your fork.
2. Install dependencies:

    ```
    $ mix deps.get
    ```

3. Set a client url you expect to receive requests from:

    ```
    # .bashrc
    export SIRKO_CLIENT_URL="http://localhost:3000"
    ```

4. Launch the app:

    ```
    $ iex -S mix
    ```

5. Setup the [sirko client](https://github.com/dnesteryuk/sirko-client) for your project.

### Testing

The app uses [ExUnit](http://elixir-lang.org/docs/stable/ex_unit/ExUnit.html) as a testing framework.
Execute the following command to launch the tests:

```
$ mix test
```

## License

The project is distributed under the [GPLv3 license](https://github.com/dnesteryuk/sirko-engine/blob/master/LICENSE.txt).
