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
	{ok, Hosts} = application:get_env(hosts),
	{ok, DefaultReadSize} = application:get_env(defaultreadsize),
	{ok, Files} = file:list_dir(Filedir),
	First2 = [filename:join([Filedir, File]) || File <- Files],
	HostsNum = length(Hosts),
	HostsSeq = [lists:nth((I rem HostsNum) + 1, Hosts) || I <- lists:seq(1, length(First2))],
	Zipped = lists:zip(HostsSeq, First2),
	io:format("There are ~p files and ~p hosts...~n", [length(Files), length(Hosts)]),
	io:format("The files are mapped to hosts as follows: ~600p~n", [Zipped]),
	{ok, #state{files_to_send = Zipped, defaultreadsize = DefaultReadSize}}.

handle_call(send, _From, State) ->
	F = fun({Host, Filename}) ->
		io:format("Sending to TCP: ~p~n", [{Host, Filename}]),
		fileop:send_file(Filename, Host, State#state.defaultreadsize),
		io:format("Sent! ~p~n", [{Host, Filename}])
	end,
	Start = erlang:monotonic_time(micro_seconds),
	ec_plists:map(F, State#state.files_to_send, 1),
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
