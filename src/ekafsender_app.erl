-module(ekafsender_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1, start/0]).


start() ->
    application:start(ekafsender).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    sc:start_link().

stop(_State) ->
    ok.
