# Changelog

## v0.1.0 (not released yet)

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

    Since it is based on a service worker, the site using the engine must be served through the secure connection (HTTPS).

## v0.0.2 (27 March 2017)

### Fixed

- An issue in IE11 which broke the sirko client for IE11 users.
- An issue with starting the project when the url to a Neo4j instance had a trailing slash.
