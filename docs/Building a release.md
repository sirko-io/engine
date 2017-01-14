# Building a release

To release the engine, a [distilery](https://github.com/bitwalker/distillery) tool gets used. It packages an elixir application which can be launched anywhere without installing Elixir and Erlang. The built package contains all dependencies. As elixir applications cannot be configured via environment variables after compilation, a [conform](https://github.com/bitwalker/conform) library is used to configure the engine in runtime.

To build a new release, follow the following steps:

1. Make sure the version of the engine in `Sirko.Mixfile` is valid.
2. Make sure the production config `config/sirko.conf` is up to date.
3. Make sure the `package.json` contains a valid version of the sirko client.
4. Build the release:

    ```
    $ MIX_ENV=prod mix release --env=prod
    ```

4. Prepare the release on the GirHub and upload `_build/prod/rel/sirko/releases/x.x.x/sirko.tar.gz`
