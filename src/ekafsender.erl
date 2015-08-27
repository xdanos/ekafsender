-module(ekafsender).

%% ekafsender: ekafsender library's entry point.

-export([send_file/3]).

send_file(Filename, Hosts, {Topic, Partition}) ->
	{ok, ReadDevice} = file:open(Filename, [raw, read_ahead, read, binary]),
	{ok, Pid} = brod:start_link_producer(Hosts, 0, 1000),
	ok = for_each_line(ReadDevice, Pid, 1000, [], {Topic, Partition}).

for_each_line(ReadDevice, Pid, 0, Buffer, {Topic, Partition}) ->
	brod:produce(Pid, Topic, Partition, lists:reverse(Buffer)),
	for_each_line(ReadDevice, Pid, 1000, [], {Topic, Partition});
for_each_line(ReadDevice, Pid, Batch, Buffer, {Topic, Partition}) ->
	case file:read_line(ReadDevice) of
		eof ->
			case length(Buffer) of
				0 ->
					ok;
				_ ->
					brod:produce(Pid, Topic, Partition, lists:reverse(Buffer)),
					ok
			end,
			file:close(ReadDevice);
		{ok, Line} ->
			for_each_line(ReadDevice, Pid, Batch - 1, [{<<>>, Line}| Buffer], {Topic, Partition})
	end.