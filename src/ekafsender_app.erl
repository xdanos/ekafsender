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
    sender:start_link(),
    receiver:start_link(),
    io:format("Sending dataset...", []),
    sender:send(),
    {ok, self()}.

stop(_State) ->
    io:format("Stopping...~n", []),
    init:stop().
