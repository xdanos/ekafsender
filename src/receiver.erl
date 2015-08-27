%%%-------------------------------------------------------------------
%%% @author xtovarn
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. VIII 2015 18:28
%%%-------------------------------------------------------------------
-module(receiver).
-author("xtovarn").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3]).

-include_lib("brod/include/brod.hrl").

-record(state, {pid :: pid()}).

%%%===================================================================
%%% API
%%%===================================================================
start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
	{ok, OutTopic} = application:get_env(outtopic),
	{ok, Hosts} = application:get_env(hosts),
	{ok, Pid} = brod:start_consumer(Hosts, OutTopic, 0),
	ok = brod:consume(Pid, self(), -1, 1000, 1, 100000),
	{ok, #state{pid = Pid}}.

handle_call(_Request, _From, State) ->
	{reply, ok, State}.

handle_cast(_Request, State) ->
	{noreply, State}.

handle_info(#message_set{messages = Msgs}, State) ->
	End = erlang:monotonic_time(micro_seconds),
	io:format("Result recieved: ~p~n", [Msgs]),
	sender:result_received(End),
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% {ok, Producer} = brod:start_link_producer([{"sc6", 9092}, {"sc7", 9092}]), brod:produce(Producer, <<"out">>, 0, <<>>, <<"message!">>).