# Sirko Engine

[![Build Status](https://travis-ci.org/sirko-io/engine.svg?branch=master)](https://travis-ci.org/sirko-io/engine)

It is a simple engine to track users' navigation on a site and predict the next page which most likely will be visited by the current user.
As soon as the engine predicts the next page, a client part of the solution adds a hint for the browser in order to prerender the predicted page. In some cases, the load of the prerendered page is close to be instant, hence, the end user gets faster response and better experience.

- A full description of the prerendering idea can be found in [this article](http://nesteryuk.info/2016/09/27/prerendering-pages-in-browsers.html).
- How it works in Chrome you can read [here](https://www.chromium.org/developers/design-documents/prerender).

Currently, this solution is only recommended for public pages which meet the following criteria:

- **pages aren't personalized**. There are bugs related to a transition from the anonymous state to the authorized one.
- **pages aren't too diverse**. For instance, if you have an online store with a lot of products, this solution won't work well. To make correct predictions for a such site, historical data of users' purchases, views and other stuff must be used.

[Try demo](http://demo.sirko.io)

### Users on mobile devices

In order to save a battery of users on mobile devices the engine doesn't track such users.

## Table of contents

- [Installation](#installation)
  - [Install with Docker](#install-with-docker)
  - [Install with Docker Compose](#install-with-docker-compose)
  - [Install without containers](#install-without-containers)
  - [Nginx virtual host](#nginx-virtual-host)
  - [Client integration](#client-integration)
- [Getting accuracy](#getting-accuracy)
- [Catching errors](#catching-errors)
- [Development](#development)
- [License](#license)

# Installation

There are at least 3 ways to install the engine. The easiest one is to install it with [Docker](#install-with-docker) or [Docker Compose](#install-with-docker-compose) (it installs Neo4j along with the engine). But, if you have reasons not to use Docker, follow [this instruction](#install-without-containers).

**IMPORTANT:** The instructions (besides the one about Docker Compose) suppose that Neo4j 3.0 or greater is already [installed](http://neo4j.com/docs/operations-manual/3.1/installation/) on your server or you got an account from one of [Neo4j cloud hosting providers](https://neo4j.com/developer/guide-cloud-deployment/#_neo4j_cloud_hosting_providers). **If you decide to host a Neo4j instance on your server, please, make sure you have at least 2 Gb of free RAM.**

## Install with [Docker](http://docker.com)

1. Download a config file:

    ```
    $ wget https://raw.githubusercontent.com/sirko-io/engine/v0.0.1/config/sirko.conf
    ```

2. Define your settings in the config file:

    ```
    $ nano sirko.conf
    ```

3. Launch a docker container:

    ```
    $ sudo docker run -d --name sirko -p 4000:4000 --restart always -v ~/sirko.conf:/usr/local/sirko/sirko.conf dnesteryuk/sirko:latest
    ```

    **IMPORTANT:** If you host the Neo4j instance on your server, you have to make sure the engine has access to it. To do that, use a network argument while launching the container:

    ```
    $ sudo docker run -d --name sirko -p 4000:4000 --restart always --network host -v ~/sirko.conf:/usr/local/sirko/sirko.conf dnesteryuk/sirko:latest
    ```

4. Verify what happens to the engine:

    ```
    $ sudo docker logs sirko
    ```

  If you see a message like this:

      2017-02-26 10:22:02.551 [info] Expecting requests from http://localhost

  the engine is running and it is ready to accept requests.

## Install with [Docker Compose](https://docs.docker.com/compose/)

1. Download a config file:

   ```
   $ wget https://raw.githubusercontent.com/sirko-io/engine/v0.0.1/config/sirko.conf
   ```

2. Define your settings in the config file:

    ```
    $ nano sirko.conf
    ```

    Please, use a `http://neo4j:7474` url for the `neo4j.url` setting.

3. Create a docker-compose.yml file:

    ```
    $ nano docker-compose.yml
    ```

    copy and past the following content:

    ```yaml
    version: '2'
    services:
      neo4j:
        image: neo4j:3.1.1
        restart: always
        environment:
          - NEO4J_AUTH=none
        ports:
          - "7474:7474"

      sirko:
        image: dnesteryuk/sirko:latest
        restart: always
        volumes:
          - ./sirko.conf:/usr/local/sirko/sirko.conf
        ports:
          - "4000:4000"
        links:
          - neo4j
    ```

4. Launch the engine and Neo4j:

    ```
    $ sudo docker-compose up -d
    ```

4. Verify what happens to the engine:

    ```
    $ sudo docker-compose logs sirko
    ```

  If you see a message like this:

      2017-02-26 10:17:19.408 [info] Expecting requests from http://localhost

  the engine is running and it is ready to accept requests.

  **Note:** You might see errors there as well. It happens when the engine gets launched before Neo4j gets accessible. Just give it a few more seconds, it is a [known](https://github.com/sirko-io/engine/issues/18) problem.

## Install without containers

**IMPORTANT:** Currently, the compiled version of the engine can only be launched on Debian/Ubuntu x64. If you use another distributive, consider the use of the docker container.

1. Download the latest release:

    ```
    $ wget https://github.com/sirko-io/engine/releases/download/v0.0.1/sirko.tar.gz
    ```

2. Unpack the archive:

    ```
    $ sudo mkdir /usr/local/sirko
    $ sudo chown ubuntu:ubuntu /usr/local/sirko
    $ cd /usr/local/sirko
    $ tar xfz /home/ubuntu/latest.tar.gz
    ```

3. Setup [Systemd](https://en.wikipedia.org/wiki/Systemd) which will manage the engine:

    ```
    sudo nano /lib/systemd/system/sirko.service
    ```

    copy and past the following content:

    ```
    [Unit]
    Description=Sirko Engine
    After=network.target

    [Service]
    Type=simple
    ExecStart=/usr/local/sirko/bin/sirko start
    ExecStop=/usr/local/sirko/bin/sirko stop
    Restart=on-failure
    RemainAfterExit=yes
    RestartSec=5
    User=ubuntu
    Environment=LANG=en_US.UTF-8

    [Install]
    WantedBy=multi-user.target
    ```

    **Note:** You are welcome to use any other alternative to Systemd.

4. Define your settings in a config file:

    ```
    $ nano /usr/local/sirko/sirko.conf
    ```

5. Launch the engine:

    ```
    $ sudo systemctl daemon-reload
    $ sudo systemctl enable sirko.service
    $ sudo systemctl start sirko.service
    ```

    To make sure, it is successfully launched, check its status:

    ```
    $ systemctl status sirko.service
    ```

    If you see a response like this:

    ```
    ● sirko.service - Sirko Engine
    Loaded: loaded (/lib/systemd/system/sirko.service; static; vendor preset: enabled)
    Active: active (running) since Mon 2017-01-23 16:45:01 UTC; 17s ago

    ```

    the engine is running and it is ready to accept requests.

### Nginx virtual host

1. Create a nginx virtual host for the engine:

    ```
    $ sudo touch /etc/nginx/sites-available/sirko
    $ sudo ln -s /etc/nginx/sites-available/sirko /etc/nginx/sites-enabled/sirko
    $ sudo nano /etc/nginx/sites-available/sirko
    ```

2. Copy and past the following content:

    ```
    upstream sirko {
        server 127.0.0.1:4000;
    }
    server{
        listen 80;
        server_name sirko.yourhostname.tld;

        location / {
            try_files $uri @proxy;
        }

        location @proxy {
            include proxy_params;
            proxy_redirect off;
            proxy_pass http://sirko;
        }
    }
    ```

8. Restart Nginx:

    ```
    $ sudo service nginx restart
    ```

### Client integration

Once you've got the engine installed, you need to integrate the client part of the solution to your site. The [sirko client](https://github.com/sirko-io/client) is a JavaScript library which prepares data and sends them to the engine.

To get it in your site, add the following code before `</head>`:

```html
<script async src="http://__URL_TO_ENGINE_HERE__/assets/client.js"></script>
<script>
  (function(w,m){w[m]=function(){w[m].q.push(arguments);};w[m].q=[];})(window,'sirko');
  sirko('engineUrl', '__URL_TO_ENGINE_HERE__');
</script>
```

**Note:** Please, don't forget to replace the placeholder with a real url.

Once you've integrated the client, visit your site, open a development webtool (F12) and make sure that requests to the engine have status 200.

## Getting accuracy

If you want to know accuracy of predictions made for your site, you can integrate the sirko client with a tracking service which is able to track custom events and execute formulas over written data. Use the following code as an example:

```html
<script>
  window.onload = function() {
    sirko('predicted', function(currentPrediction, isPrevCorrect) {
      if (isPrevCorrect !== undefined) {
        // call your tracking service here
      }
    });
  };
</script>
```

**Note:** The second argument is undefined when it is a first visit of the current user. In this case, there is nothing to track.

The code example uses the onload callback to be sure that all dependencies get loaded, But, the sirko client can be called earlier, just verify the documentation to your tracking service when you can send custom events. Some tracking services can be called without waiting for loading the whole content.

## Catching errors

You might want to catch errors which happen to the engine and report them. The engine got integrated with [Rollbar](https://rollbar.com) which notifies you about errors via an email or a messenger (it supports a few). To start using it, register an account and add your rollbar access token to the `sirko.conf`.

## Development

### Dependencies

 - [Elixir](http://elixir-lang.org/install.html) 1.4.*
 - [Neo4j](https://neo4j.com/download/) 3.*
 - [Npm](https://npmjs.com)

If you use [Docker](https://www.docker.com/), execute the following command to install Neo4j:

```
$ sudo docker run --name neo4j-db -d -e NEO4J_AUTH=none --restart always -p 7474:7474 neo4j:3.1
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

5. [Integrate](#client-integration) the sirko client into a site you want to use for testing.

**Note:** If you don't have a site to check your changes, you can clone [this demo site](https://github.com/sirko-io/demo) and locally set it up.

### Testing

The app uses [ExUnit](http://elixir-lang.org/docs/stable/ex_unit/ExUnit.html) as a testing framework.
Execute the following command to launch the tests:

```
$ mix test
```

## License

The project is distributed under the [GPLv3 license](https://github.com/sirko-io/engine/blob/master/LICENSE.txt).
