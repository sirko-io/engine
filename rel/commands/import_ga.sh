#!/bin/sh

release_ctl eval --mfa "Mix.Tasks.Sirko.ImportGa.run/1" --argv -- "$@"
