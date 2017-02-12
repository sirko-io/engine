# Sirko Engine

[![Build Status](https://travis-ci.org/dnesteryuk/sirko-engine.svg?branch=master)](https://travis-ci.org/dnesteryuk/sirko-engine)

It is a simple engine to track users' navigation on a site and predict the next page which most likely will be visited by the current user.
As soon as the engine predicts the next page, a client part of the solution adds a hint for the browser in order to prerender the predicted page. In some cases, the load of the prerendered page is close to be instant, hence, the end user gets faster response and better experience.

- A full description of the prerendering idea can be found in [this article](http://nesteryuk.info/2016/09/27/prerendering-pages-in-browsers.html).
- How it works in the Chrome you can read [here](https://www.chromium.org/developers/design-documents/prerender).

Currently, this solution is only recommended for public pages which meet the following criteria:

- **pages aren't personalized**. There are bugs related to a transition from the anonymous state to the authorized one.
- **pages aren't too diverse**. For instance, if you have an online store with a lot of products, this solution won't work well. To make correct predictions for a such site, historical data of users' purchases, views and other stuff must be used.

[Try demo](http://demo.sirko.io)

### Users on mobile devices

In order to save a battery of users on mobile devices the engine doesn't track users.

## Table of contents

- [Installation](#installation)
  - [Manual installation](#manual-installation)
  - [Install with Docker](#install-with-docker)
  - [Nginx virtual host](#nginx-virtual-host)
  - [Client integration](#client-integration)
- [Getting accuracy](#getting-accuracy)
- [Catching errors](#catching-errors)
- [Development](#development)
- [License](#license)

# Installation

The easiest way to install the engine is to use a [docker image](#install-with-docker). But, if you have reasons to not use Docker, follow the instruction below.

**IMPORTANT:** The following instruction supposes that Neo4j 3.0 or greater is already [installed](http://neo4j.com/docs/operations-manual/3.1/installation/) on your server or you got an account from one of [Neo4j cloud hosting providers](https://neo4j.com/developer/guide-cloud-deployment/#_neo4j_cloud_hosting_providers).

## Manual installation

1. Download the latest release:

    ```
    $ wget https://github.com/sirko-io/engine/archive/latest.tar.gz
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

4. Edit a configuration file:

    ```
    $ nano /usr/local/sirko/sirko.conf
    ```

    There, you have to define a url to your Neo4j instance and credentials, also, you need to specify a url to your site for which you want to make predictions.

5. Start the engine:

    ```
    $ sudo systemctl daemon-reload
    $ sudo systemctl enable sirko.service
    $ sudo systemctl start sirko.service
    ```

    To make sure, it is successfully started, you can check its status:

    ```
    $ systemctl status sirko.service
    ```

    If you see a response like this:

    ```
    ● sirko.service - Sirko Engine
    Loaded: loaded (/lib/systemd/system/sirko.service; static; vendor preset: enabled)
    Active: active (running) since Mon 2017-01-23 16:45:01 UTC; 17s ago

    ```

    it's started.

## Install with Docker

1. Download and save a config file in some directory on your server:

   ```
   $ wget https://raw.githubusercontent.com/sirko-io/engine/latest/config/sirko.conf
   ```

2. Define your settings in the downloaded configuration file:

    ```
    $ nano sirko.conf
    ```

3. Launch the docker container:

    ```
    $ sudo docker run -d --name sirko -p 4000:4000 --restart always -v ./sirko.conf:/usr/local/sirko/sirko.conf sirko:latest

    ```

4. Verify what happens to the engine:

    ```
    $ sudo docker logs sirko
    ```

  If you see a message like this:

      Expecting requests from http://localhost:3000

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

Once you've integrated the client, visit your site and make sure through a development webtool (F12) that requests to the engine have status 200.

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

**Note::** The second argument is undefined when it is a first visit of the current user. In this case, there is nothing to track.

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
