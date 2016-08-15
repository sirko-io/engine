# Sirko Engine

A simple engine to track users' navigation on a site and predict a next page which most likely will be visited by the current user. As soon as we are able to predict the next page, we can prerender that page in order to provide better experience (an instant transition in some cases) to the user.

A full description of the prerendering idea can be found in [this article](http://nesteryuk.info/2016/09/27/prerendering-pages-in-browsers.html).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add sirko to your list of dependencies in `mix.exs`:

        def deps do
          [{:sirko, "~> 0.0.1"}]
        end

  2. Ensure sirko is started before your application:

        def application do
          [applications: [:sirko]]
        end

## Launch

      iex -S mix
