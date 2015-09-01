-module(fileop).

%% ekafsender: ekafsender library's entry point.

-export([send_file/3]).

send_file(Filename, _Host = {Address, Port}, DefaultReadSize) ->
	{ok, ReadDevice} = file:open(Filename, [raw, read_ahead, read, binary]),
	{ok, Socket} = gen_tcp:connect(Address, Port, [], 5000),
	ok = for_each_line(ReadDevice, Socket, DefaultReadSize, [], DefaultReadSize).

for_each_line(ReadDevice, Socket, 0, Buffer, DefaultReadSize) ->
	gen_tcp:send(Socket, lists:reverse(Buffer)),
	for_each_line(ReadDevice, Socket, DefaultReadSize, [], DefaultReadSize);
for_each_line(ReadDevice, Socket, BatchCounter, Buffer, DefaultReadSize) ->
	case file:read_line(ReadDevice) of
		eof ->
			case length(Buffer) of
				0 ->
					ok;
				_ ->
					gen_tcp:send(Socket, lists:reverse(Buffer)),
					ok
			end,
			gen_tcp:close(Socket),
			file:close(ReadDevice);
		{ok, Line} ->
			for_each_line(ReadDevice, Socket, BatchCounter - 1, [Line | Buffer], DefaultReadSize)
	end.