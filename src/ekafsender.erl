-module(ekafsender).

%% ekafsender: ekafsender library's entry point.

-export([send_file/3]).

send_file(Filename, Hosts, {Topic, Partition, DefaultReadSize}) ->
	{ok, ReadDevice} = file:open(Filename, [raw, read_ahead, read, binary]),
	{ok, Pid} = brod:start_link_producer(Hosts, 1, 1000),
	ok = for_each_line(ReadDevice, Pid, DefaultReadSize, [], {Topic, Partition, DefaultReadSize}).

for_each_line(ReadDevice, Pid, 0, Buffer, {Topic, Partition, DefaultReadSize}) ->
	brod:produce(Pid, Topic, Partition, lists:reverse(Buffer)),
	for_each_line(ReadDevice, Pid, DefaultReadSize, [], {Topic, Partition, DefaultReadSize});
for_each_line(ReadDevice, Pid, BatchCounter, Buffer, {Topic, Partition, DefaultReadSize}) ->
	case file:read_line(ReadDevice) of
		eof ->
			case length(Buffer) of
				0 ->
					ok;
				_ ->
					brod:produce(Pid, Topic, Partition, lists:reverse(Buffer)),
					ok
			end,
			brod_producer:stop(Pid),
			file:close(ReadDevice);
		{ok, Line} ->
			for_each_line(ReadDevice, Pid, BatchCounter - 1, [{<<>>, Line}| Buffer], {Topic, Partition, DefaultReadSize})
	end.