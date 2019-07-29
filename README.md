# Sirko Engine

[![Build Status](https://travis-ci.org/sirko-io/engine.svg?branch=master)](https://travis-ci.org/sirko-io/engine)

It is a solution for supporting users during navigation. Learning how users navigate the engine precaches resources (pages, JS, image and CSS files) a user might need in a next transition. The precached resources get accumulated for offline use and get served when the user is offline. Precaching resources and offline work improve user's experience and engagement rate.

Motivation and technical details are described in [that article](https://nesteryuk.info/2018/04/08/automate-precaching-resources.html).

Currently, this solution is only recommended for pages which meet the following criteria:

- **pages aren't too diverse**. For instance, if you have online store with lots of products, this solution won't work well. To make correct predictions for such a site, historical data of users' purchases, views and other stuff must be used.
- **pages are served over a secure connection (HTTPS)**. The client part is based on a [service worker](https://developers.google.com/web/fundamentals/getting-started/primers/service-workers).

[Try demo](https://sirko-demo.nesteryuk.info)

### Help is needed

Data driven solutions need data. The current prediction is naive. I've been trying to see how the model might be improved by adding [K-mean](https://en.wikipedia.org/wiki/K-means_clustering) for splitting users by screen sizes and Higher Order Markov Model for considering previously visited pages. So, if you want to improve the solution, you might extract user sessions of your Google Analytics account and send it to [me](https://github.com/dnesteryuk), [here is a request](https://gist.github.com/dnesteryuk/9ac528b0ff822ff9b0f8005c81fa4f6c#file-request-json) which extracts data I am interested in. As you can see, the request fetches rows containing a previous page, a current page, a browser size and date. The response will [look like this](https://gist.github.com/dnesteryuk/9ac528b0ff822ff9b0f8005c81fa4f6c#file-response_example-json), you might try out the request [here](https://developers.google.com/analytics/devguides/reporting/core/v4/rest/v4/reports/batchGet).

## Table of contents

- [Installation](#installation)
  - [Install with Docker](#install-with-docker)
  - [Install with Docker Compose](#install-with-docker-compose)
  - [Install without containers](#install-without-containers)
  - [Nginx virtual host](#nginx-virtual-host)
  - [Client integration](#client-integration)
- [Importing data from Google Analytics](#importing-data-from-google-analytics-ga)
- [Offline work](#offline-work)
- [Prefetching images](#prefetching-images)
- [Getting accuracy](#getting-accuracy)
- [Catching errors](#catching-errors)
- [Browser support](#browser-support)
- [Contributing](/CONTRIBUTING.md)
- [Changelog](/CHANGELOG.md)
- [License](#license)

# Installation

There are at least 3 ways to install the engine. The easiest one is to install it with [Docker](#install-with-docker) or [Docker Compose](#install-with-docker-compose) (it installs Neo4j along with the engine). But, if you have reasons not to use Docker, follow [this instruction](#install-without-containers).

**IMPORTANT:** The instructions (besides the one about Docker Compose) suppose that Neo4j 3.4 or greater is already [installed](http://neo4j.com/docs/operations-manual/3.4/installation/) on your server or you got an account from one of [Neo4j cloud hosting providers](https://neo4j.com/developer/neo4j-cloud-hosting-providers/). **If you decide to host a Neo4j instance on your server, please, make sure you have at least 2 Gb of free RAM.**

## Install with [Docker](http://docker.com)

1. Download a config file:

    ```
    $ wget https://raw.githubusercontent.com/sirko-io/engine/v0.5.0/config/sirko.toml -O sirko.conf
    ```

2. Define your settings in the config file:

    ```
    $ nano sirko.conf
    ```

3. Launch a docker container:

    ```
    $ sudo docker run -d --name sirko \
                      -p 4000:4000 \
                      --restart always \
                      -v ~/sirko.conf:/usr/local/sirko/sirko.conf \
                      dnesteryuk/sirko:latest
    ```

    **IMPORTANT:** If you host the Neo4j instance on your server, you have to be sure the engine has access to it. To do that, use a network argument while launching the container:

    ```
    $ sudo docker run -d --name sirko \
                      -p 4000:4000 \
                      --restart always \
                      -v ~/sirko.conf:/usr/local/sirko/sirko.conf \
                      --network host \
                      dnesteryuk/sirko:latest
    ```

4. Verify what happens to the engine:

    ```
    $ sudo docker logs sirko
    ```

  If you see a message like this:

      2018-10-27 08:29:57.154 [info] The current version is 0.5.0. If you have questions/issues, please, report them https://github.com/sirko-io/engine/issues
      2018-10-27 08:29:57.154 [info] Expecting requests from http://localhost

  the engine is running and it is ready to accept requests.

## Install with [Docker Compose](https://docs.docker.com/compose/)

1. Download a config file:

   ```
   $ wget https://raw.githubusercontent.com/sirko-io/engine/v0.5.0/config/sirko.toml -O sirko.conf
   ```

2. Define your settings in the config file:

    ```
    $ nano sirko.conf
    ```

    Please, use a `http://neo4j:7687` URL for the `neo4j.url` setting.

3. Create a docker-compose.yml file:

    ```
    $ nano docker-compose.yml
    ```

    copy and past the following content:

    ```yaml
    version: '2'
    services:
      neo4j:
        image: neo4j:3.4.6
        restart: always
        environment:
          - NEO4J_AUTH=none
        ports:
          - "7687:7687"

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

      2018-10-27 08:29:57.154 [info] The current version is 0.5.0. If you have questions/issues, please, report them https://github.com/sirko-io/engine/issues
      2018-10-27 08:29:57.154 [info] Expecting requests from http://localhost

  the engine is running and it is ready to accept requests.

## Install without containers

**IMPORTANT:** Currently, the compiled version of the engine can only be launched on Debian/Ubuntu x64. If you use another distributive, consider the use of the docker container.

The instruction supposes that you have a ubuntu user, please, don't forget to replace it with an appropriate user for your sever.

1. Download the latest release:

    ```
    $ wget https://github.com/sirko-io/engine/releases/download/v0.5.0/sirko.tar.gz
    ```

2. Unpack the archive:

    ```
    $ sudo mkdir /usr/local/sirko
    $ sudo chown ubuntu:ubuntu /usr/local/sirko
    $ cd /usr/local/sirko
    $ tar xfz /home/ubuntu/sirko.tar.gz
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

## Nginx virtual host

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
        listen 443 ssl http2;

        server_name sirko.yourhostname.tld;

        gzip on;
        gzip_types text/javascript application/javascript;
        gzip_comp_level 5;

        location / {
            include proxy_params;
            proxy_redirect off;
            proxy_pass http://sirko;

            if ($request_uri ~* "\.js$") {
                expires 7d;
                add_header Pragma public;
                add_header Cache-Control "public";
            }
        }
    }
    ```

3. Restart Nginx:

    ```
    $ sudo service nginx restart
    ```

4. Acquire a SSL certificate for your site. The easiest way is to use [Certbot](https://certbot.eff.org).

### Client integration

Once you've got the engine installed, you need to integrate the client part of the solution to your site. The [sirko client](https://github.com/sirko-io/client) is a JavaScript library which prepares data and sends them to the engine.

To get it in your site, add the following code before `</head>`:

```html
<script>
  (function(w,m){w[m]=function(){w[m].q.push(arguments);};w[m].q=[];})(window,'sirko');
  sirko('engineUrl', '__URL_TO_ENGINE_HERE__');
</script>
<script async src="__URL_TO_ENGINE_HERE__/assets/client.js"></script>
```

**Note:** Please, don't forget to replace the placeholder with a real url.

The next step is to serve the service worker script from the root of your domain, example:

```
http://demo.sirko.io/sirko_sw.js
```

The easiest way is to proxy the request to the engine. If you use Nginx, here is an example:

```
# other directives

location = /sirko_sw.js {
  proxy_pass http://127.0.0.1:4000/assets/sirko_sw.js;
}
```

Another way is to copy [this script](https://github.com/sirko-io/client/blob/master/dist/sirko_sw.js) and serve it via your backend.

Once you've integrated the client, visit your site, open a development webtool (F12) and make sure that requests to the engine have status 200. If you use Chrome, click on the _Application_ tab, then click on the _Service workers_ item in the left sidebar. There you should see all registered service workers on your page. You need to find a `sirko_sw.js` service worker, it should have the `activated and running` state and no errors.

## Importing data from Google Analytics (GA)

To get realistic predictions, it takes time to gather data. Although, you can import sessions from your GA account, thus, you can see benefits of the solution right after installation. Data gets exported from [Analytics Reporting API](https://developers.google.com/analytics/devguides/reporting/core/v4/), so you will need to grant access to your GA account. After importing, the engine doesn't need access to GA, so you can revoke it.

Before running the import command, you need to follow [those 7 steps](https://developers.google.com/adwords/api/docs/guides/authentication#installed) to acquire the client ID and client secret. Then, you need to follow [those 5 steps](https://stackoverflow.com/a/47921777/321215) to find your Analytics View Id.

Now you are ready to import sessions.

Run if the engine was installed without Docker:

```
$ bin/sirko import_ga <your_client_id> <your_client_secret> <your_view_id>
```

Otherwise:

```
$ sudo docker exec -ti sirko bin/sirko import_ga <your_client_id> <your_client_secret> <your_view_id>
```

There are a few restrictions you need to know about:

 - The imported pages won't have assets, thus, assets cannot be prefetched until the engine gets them from the client (it happens when a user visits pages, so this gap will be automatically filled overtime).
 - There is a difference between the engine and GA in tracking sessions, thus, the prediction accuracy by using the imported data might be different.
 - The engine imports sessions for a number of days defined in a `sirko.engine.stale_session_in` setting (you can find it in a `config/sirko.conf` file).
 - If a site has lots of visitors, GA will have ton of records. Mostly, all data isn't required, so the engine imports 500,000 records at most.

## Offline work

By default, all precached resources get removed once the user navigates to a next page. It is a necessary step to avoid shipping stale pages. If you want your site to work offline, you might enable an offline mode by adding:

```javascript
sirko('offline', true);
```

to the script block where you've defined the url to the engine. This option means all precached resources should be kept in the cache and served when the user is offline. Only pages which were predicted by the engine will work offline.

If you want to cache the entire site for offline use, you need to open the `config/sirko.conf` file and set

```
[sirko.engine]

# now all pages will pass the threshold
confidence_threshold = 0

# hopefully, your site has less number of pages than this value
max_pages_in_prediction = 1000000000
```

This configuration means that all pages will be fetched whenever the user moves to another page. Even if they are cached, they will be fetched again to keep the most fresh version. The load on your backend might be reduced if you set expiration for your resources, a [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) which is used in precaching resources respects the [Cache control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control) header.

## Prefetching images

By default, only URLs to JS and CSS files get gathered. Although, there is a way to gather URLs to images and later prefetch them:

```javascript
sirko('imagesSelector', 'img');
```

The provided selector must be a valid [CSS selector](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Selectors).

## Getting accuracy

If you want to know accuracy of predictions made for your site, you might integrate the sirko client with a tracking service which is able to track custom events and execute formulas over written data. Use the following code as an example:

```html
<script>
  window.onload = function() {
    sirko('predicted', function(currentPrediction, isPrevCorrect) {
      if (isPrevCorrect !== undefined) {
        console.info('The previous prediction was', isPrevCorrect ? 'correct' : 'incorrect');
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

## Browser support

The solution works in browsers which [support service workers](https://caniuse.com/#search=serviceworker).

However, mobile users are ignored now. Navigation on mobile devices might be different, thus, to make correct predictions for desktop and mobile users we need to split them in the prediction model. It will be developed later.

## License

The project is distributed under the [GPLv3 license](https://github.com/sirko-io/engine/blob/master/LICENSE.txt).
