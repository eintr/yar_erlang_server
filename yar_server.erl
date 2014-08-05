-module(yar_server).

-export([test_drive/1]).

-author("牛海青<nhf0424@gmail.com>").

-include("yar_msg.hrl").

test_drive(Socket) ->
	case yar_msg:recv_decode(Socket) of
		{ok, {_Header, Msg}} ->
			io:format("Received: ~p:~s(~p)~n", [Msg#yar_msg_body.id, Msg#yar_msg_body.method, Msg#yar_msg_body.parameter]),
			yar_msg:encode_send(Socket, example_answer()),
			test_drive(Socket);
		{error, Reason} ->
			io:format("Receive error: ~p~n", [Reason])
	end.

example_answer() ->
	{1000, #{"status"=>0, "parameters"=>nil, "data"=>[true, 0.234200, "dummy"]}}.

