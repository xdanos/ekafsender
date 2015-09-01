#!/bin/bash
erl -name node -s ekafsender_app -pa ebin/ deps/*/ebin/ -noshell +A 32 -config config/ekafsender.config
