# Sirko Engine

[![Build Status](https://travis-ci.org/dnesteryuk/sirko-engine.svg?branch=master)](https://travis-ci.org/dnesteryuk/sirko-engine)

It is a simple engine to track users' navigation on a site and predict the next page which most likely will be visited by the current user.
As soon as we are able to predict the next page, we can prerender that page in order to provide better experience (an instant transition in some cases) to the user.

A full description of the prerendering idea can be found in [this article](http://nesteryuk.info/2016/09/27/prerendering-pages-in-browsers.html).
How it works in the Chrome you can read [here](https://www.chromium.org/developers/design-documents/prerender).

[Try demo](http://demo.sirko.io)

## Usage

The easiest way to install the application is to use a [docker image](https://github.com/dnesteryuk/sirko-docker).

But, if you have reasons to not use Docker, follow the instruction below.

### Installation

**IMPORTANT:** The following instruction supposes that Neo4j is already [installed](http://neo4j.com/docs/operations-manual/3.1/installation/) on your server or you got an account from one of [Neo4j cloud hosting providers](https://neo4j.com/developer/guide-cloud-deployment/#_neo4j_cloud_hosting_providers).

1. Open a terminal and access your server through SSH.
2. Download the latest release:

    ```
    $ curl https://github.com/dnesteryuk/sirko-engine/archive/latest.tar.gz
    ```

3. Unpack the archive:

    ```
    $ sudo mkdir /usr/local/sirko
    $ sudo chown ubuntu:ubuntu /usr/local/sirko
    $ cd /usr/local/sirko
    $ tar xfz /home/ubuntu/latest.tar.gz
    ```

4. Setup [systemd](https://en.wikipedia.org/wiki/Systemd) which will manage the engine:

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

    **Note:** You are welcome to use any other alternative to systemd.

5. Edit a sirko configuration file:

    ```
    $ nano /usr/local/sirko/sirko.conf
    ```

    There, you have to define a url to your Neo4j instance and credentials, also, you need to specify a url to your site for which you want to make predictions.

6. Start the engine:

    ```
    $ sudo systemctl daemon-reload
    $ sudo systemctl enable sirko.service
    $ sudo systemctl start sirko.service
    ```

    To make sure, it is successfully started, you can check it status:

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

7. Create a nginx virtual host for the engine:

    ```
    $ sudo touch /etc/nginx/sites-available/sirko
    $ sudo ln -s /etc/nginx/sites-available/sirko /etc/nginx/sites-enabled/sirko
    $ sudo nano /etc/nginx/sites-available/sirko
    ```

    add content to the created file:

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

8. Restart nginx:

    ```
    $ sudo service nginx restart
    ```

9. Check documentation of a [sirko client](https://github.com/dnesteryuk/sirko-client) and embed it to your site.

## Development

### Dependencies

 - [Elixir](http://elixir-lang.org/install.html) 1.3.* or 1.4.*
 - [Neo4j](https://neo4j.com/download/) 3.*
 - [Npm](https://npmjs.com)

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

5. Check documentation of the [sirko client](https://github.com/dnesteryuk/sirko-client) and embed it to a site you want to use for testing.

**Note:** If you don't have a site to check your changes, you can clone [this demo site](https://github.com/dnesteryuk/sirko-demo) and locally set it up.

### Testing

The app uses [ExUnit](http://elixir-lang.org/docs/stable/ex_unit/ExUnit.html) as a testing framework.
Execute the following command to launch the tests:

```
$ mix test
```

## License

The project is distributed under the [GPLv3 license](https://github.com/dnesteryuk/sirko-engine/blob/master/LICENSE.txt).
