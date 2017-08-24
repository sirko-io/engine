# Changelog

## v0.2.0 (Not released  yet)

### Changed

- The engine doesn't prerender pages anymore. The previous release provided fallback to browsers which don't support the prerender hint. Since the Chrome team deprecated the prerender hint, that fallback turned to a main solution. Now, the client side of Sirko Engine prefetches a predicted page and serves it from the cache once the user visits that page. It means if you already use v0.1.0, the following code can be removed:

    ```javascript
    sirko('useFallback', true);
    ```

    Also, it is mandatory to serve a `sirko_sw.js` script from the root of your domain, example:

    ```
    https://demo.sirko.io/sirko_sw.js
    ```

    Please, get more details [here](https://github.com/sirko-io/engine#client-integration).

### Added

- When a page gets prefetched via a service worker, assets (images, JavaScript, CSS files) aren't fetched until the page gets shown. To speed up page loading, the engine got enhanced to store urls to assets (only JavaScript and CSS files) of a page. So, when the engine predicts a next page, the client prefetches the predicted page and assets of the page. Thus, when a user navigates to that page, the page and assets of that page get served from the browser's cache.

## v0.1.0 (15 July 2017)

### Changed

- The engine got migrate to a bolt protocol to work with Neo4j. This protocol provides better performance. **The change affects the config file.**
    To specify the url to a Neo4j instance, use the following format in the config file:

    ```
    bolt://localhost:7687
    ```

    Credentials are a part of the url:

    ```
    bolt://username:password@localhost:7687
    ```

    The following settings got removed:

    ```
    neo4j.basic_auth.username
    neo4j.basic_auth.password
    ```

    Also, there is a new setting which points either to use a secure connection to the Neo4j instance:

    ```
    neo4j.ssl = true
    ```

### Added

- Each Neo4j query gets logged when the log level is `info`. It will help in debugging slow queries.
- Duration of keeping expired sessions in the DB can be configured via `sirko.engine.stale_session_in` config setting.
    To get more details about this setting check the config/sirko.conf file.
- A new `sirko.engine.confidence_threshold` setting is introduced to define a confidence threshold which must be met
    to prerender a predicted page. Use this setting to reduce load on your backend if you get some because of the prerendering.
- The client side got a fallback solution to the prerender hint. That solution prefetches the predicted page in browsers which don't support the prerender hint. It doesn't provide the instance load, for example, in Firefox, but Firefox users get the improved experience anyway. The technical details of the implementation can be found in [this article](https://nesteryuk.info/2017/06/05/service-worker-as-fallback-to-the-prerender-resource-hint.html). In order to use the fallback, enable it on the client side:

    ```javascript
    sirko('useFallback', true);
    ```

    Since it is based on a service worker, the site which uses the engine must be served over the secure connection. Also, the site must serve a service worker script from the root of its domain, example:

    ```
    https://demo.sirko.io/sirko_sw.js
    ```

    The easiest way is to proxy the request to the engine. If you use Nginx, here is an example:

    ```
    location = /sirko_sw.js {
      proxy_pass http://127.0.0.1:4000/assets/sirko_sw.js;
    }
    ```

### Fixed

- Missing transitions when a user with the expired session continued navigating site ([#29](https://github.com/sirko-io/engine/issues/29)).

### Removed

- The starting point which was described in [this article](https://nesteryuk.info/2016/09/27/prerendering-pages-in-browsers.html) got removed. It didn't bring any value to the prediction model.

## v0.0.2 (27 March 2017)

### Fixed

- An issue in IE11 which broke the sirko client for IE11 users.
- An issue with starting the project when the url to a Neo4j instance had a trailing slash.
