%%%-------------------------------------------------------------------
%%% @author xtovarn
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. VIII 2015 9:53
%%%-------------------------------------------------------------------
-module(sc).
-author("xtovarn").

-behaviour(gen_server).

%% API
-export([start_link/0, start_producing/0]).

%% gen_server callbacks
-export([init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3]).

-record(state, {
	files_to_send :: list(),
	intopic :: any(),
	outtopic :: any(),
	partitions :: integer(),
	hosts :: list()
}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start_producing() ->
	gen_server:call(?MODULE, start_producing).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
	{ok, Filedir} = application:get_env(filedir),
	{ok, Partitions} = application:get_env(partitions),
	{ok, InTopic} = application:get_env(intopic),
	{ok, OutTopic} = application:get_env(outtopic),
	{ok, Hosts} = application:get_env(hosts),
	{ok, Files} = file:list_dir(Filedir),
	Min = min(Partitions, length(Files)),
	{First, _} = lists:split(Min, Files),
	Zipped = lists:zip(lists:seq(0, Min - 1), First),
	io:format("The files are mapped to partitions as follows: ~p~n", [Zipped]),
	{ok, #state{files_to_send = Zipped, intopic = InTopic, outtopic = OutTopic, partitions = Partitions, hosts = Hosts}}.

handle_call(start_producing, _From, State) ->
	F = fun({Parition, Filename}) ->
			ekafsender:send_file(Filename, State#state.hosts, {State#state.intopic, Parition})
		end,
	ec_plists:foreach(F, State#state.files_to_send, [{processes, 8}]),
	{reply, ok, State}.

handle_cast(_Request, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

