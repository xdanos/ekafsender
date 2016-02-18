#!/bin/bash
erl -sname node -s ekafsender_app -pa ebin/ deps/brod/ebin/ deps/erlware_commons/ebin/ -noshell +A 128
