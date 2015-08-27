#!/bin/bash
erl -name node -s ekafsender_app -pa ebin/ deps/brod/ebin/ deps/erlware_commons/ebin/
