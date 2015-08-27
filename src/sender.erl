%%%-------------------------------------------------------------------
%%% @author xtovarn
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. VIII 2015 9:53
%%%-------------------------------------------------------------------
-module(sender).
-author("xtovarn").

-behaviour(gen_server).

%% API
-export([start_link/0, send/0]).

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
	hosts :: list(),
	defaultreadsize :: integer()
}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

send() ->
	gen_server:call(?MODULE, send, infinity).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
	{ok, Filedir} = application:get_env(filedir),
	{ok, Partitions} = application:get_env(partitions),
	{ok, InTopic} = application:get_env(intopic),
	{ok, OutTopic} = application:get_env(outtopic),
	{ok, Hosts} = application:get_env(hosts),
	{ok, DefaultReadSize} = application:get_env(defaultreadsize),
	{ok, Files} = file:list_dir(Filedir),
	Min = min(Partitions, length(Files)),
	{First, _} = lists:split(Min, Files),
	First2 = [filename:join([Filedir, File]) || File <- First],
	Zipped = lists:zip(lists:seq(0, Min - 1), First2),
	io:format("There are ~p files and ~p partitions...~n", [length(Files), Partitions]),
	io:format("The files are mapped to partitions as follows: ~p~n", [Zipped]),
	{ok, #state{files_to_send = Zipped, intopic = InTopic, outtopic = OutTopic, partitions = Partitions, hosts = Hosts, defaultreadsize = DefaultReadSize}}.

handle_call(send, _From, State) ->
	F = fun({Parition, Filename}) ->
		io:format("Producing ~p~n", [{Parition, Filename}]),
		fileop:send_file(Filename, State#state.hosts, {State#state.intopic, Parition, State#state.defaultreadsize}),
		io:format("Produced ~p~n", [{Parition, Filename}])
	end,
	ec_plists:map(F, State#state.files_to_send, 4),
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