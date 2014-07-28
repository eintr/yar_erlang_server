-module(yar_msg).

-export([test_recv_decode/1, recv_decode/1, encode_send/2]).

-author("牛海青<nhf0424@gmail.com>").

-include("yar_msg.hrl").

test_recv_decode(Socket) ->
	io:format("Received: ~p~n", [recv_decode(Socket)]).

recv_decode(Socket) ->
	case gen_tcp:recv(Socket, ?sizeof_yar_msg_hdr) of
		{ok, <<	Id:32/big-unsigned-integer,
				Version:16/big-unsigned-integer,
				?yar_magic_num:32/big-unsigned-integer,
				_Reserved:32/big-unsigned-integer,
				Provider:8/unsigned-integer-unit:32,
				Token:8/unsigned-integer-unit:32,
				Body_len:32/big-unsigned-integer	>>} ->
			case recv_body(Socket, Body_len) of
				{error, Reason} ->
					{error, Reason};
				{ok, Bin} ->
					case decode_body(Bin) of
						{ok, Msg} ->
							{ok, {#yar_msg_hdr{	id=Id,
											version = Version,
											provider = Provider,
											token = Token,
											body_len = Body_len },
									Msg}};
						{error, Reason} ->
							{error, "Yar Body decode failed:" ++ Reason}
					end
			end;
		{ok, _} ->
			{error, "Header parse error"};
		{error, Reason} ->
			{error, "Socket IO error:" ++ Reason}
	end.

recv_body(Socket, Len) ->
	io:format("Recieve body, len=~p~n", [Len]),
	case gen_tcp:recv(Socket, Len) of
		{ok, List}	when is_list(List) ->
			{ok, list_to_binary(List)};
		{ok, Bin} when is_binary(Bin) ->
			{ok, Bin};
		{error, Reason} ->
			{error, "Recieve body error: " ++ Reason}
	end.

decode_body(<<Type:8/binary-unit:8, Rest/binary>>) ->
	case Type of
		<<"MSGPACK", 0>> ->
			msgpack:unpack(Rest);
		_ ->
			{error, "Unknown serializer: " ++ binary_to_list(Type)}
	end.

encode_send(_Socket, {_MsgRecord, _BodyBin}) ->
	todo.

