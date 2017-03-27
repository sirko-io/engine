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

## v0.0.2 (27 March 2017)

### Fixed

- An issue in IE11 which broke the sirko client for IE11 users.
- An issue with starting the project when the url to a Neo4j instance had a trailing slash.
