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
-export([start_link/0, send/0, result_received/1]).

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
	defaultreadsize :: integer(),
	start :: integer()
}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

send() ->
	gen_server:call(?MODULE, send, infinity).

result_received(End) ->
	gen_server:cast(?MODULE, {result_received, End}).

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
	io:format("The files are mapped to partitions as follows: ~600p~n", [Zipped]),
	{ok, #state{files_to_send = Zipped, intopic = InTopic, outtopic = OutTopic, partitions = Partitions, hosts = Hosts, defaultreadsize = DefaultReadSize}}.

handle_call(send, _From, State) ->
	F = fun({Parition, Filename}) ->
		io:format("Sending to Kafka: ~p~n", [{Parition, Filename}]),
		fileop:send_file(Filename, State#state.hosts, {State#state.intopic, Parition, State#state.defaultreadsize}),
		io:format("Sent! ~p~n", [{Parition, Filename}])
	end,
	Start = erlang:monotonic_time(micro_seconds),
	ec_plists:map(F, State#state.files_to_send, 4),
	SendEnd = erlang:monotonic_time(micro_seconds),
	io:format("The dataset was sent in: ~p milli_seconds~n", [erlang:convert_time_unit(SendEnd - Start, micro_seconds, milli_seconds)]),
	io:format("Waiting for result (max. 10 minutes), forcing to stop~n", []),
	{reply, ok, State#state{start = Start}, erlang:convert_time_unit(600, seconds, milli_seconds)}.

handle_cast({result_received, End}, State) ->
	io:format("This run took: ~p milli_seconds~n", [erlang:convert_time_unit(End - State#state.start, micro_seconds, milli_seconds)]),
	application:stop(ekafsender),
	{noreply, State}.

handle_info(timeout, State) ->
	io:format("The output took more than 10 minutes~n", []),
	application:stop(ekafsender),
	{noreply, State};

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================