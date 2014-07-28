-module(yar_msg).

-export([recv_decode/1, encode_send/2]).

-author("牛海青<nhf0424@gmail.com>").

-include("yar_msg.hrl").

recv_decode(Socket) ->
	case gen_tcp:recv(Socket, sizeof_yar_msg_hdr) of
		{ok, <<	Id:32/big-unsigned-integer,
				Version:16/big-unsigned-integer,
				Magic_num:32/big-unsigned-integer,
				_Reserved:16/big-unsigned-integer,
				Provider:8/unsigned-integer-unit:32,
				Token:8/unsigned-integer-unit:32,
				Body_len:32/big-unsigned-integer	>>} ->
			case recv_body(Socket, Body_len) of
				{error, Reason} ->
					{error, Reason};
				{ok, Bin} ->
					{ok, {#yar_msg_hdr{	id=Id,
									version = Version,
									magic_num = Magic_num,
									provider = Provider,
									token = Token,
									body_len = Body_len },
							Bin}
					}
			end;
		{ok, _} ->
			{error, "Header parse error"};
		{error, Reason} ->
			{error, "Socket IO error:" ++ Reason}
	end.

recv_body(Socket, Len) ->
	case gen_tcp:recv(Socket, Len) of
		{ok, List}	when is_list(List) ->
			{ok, list_to_binary(List)};
		{ok, Bin} when is_binary(Bin) ->
			{ok, Bin};
		{error, Reason} ->
			{error, "Recieve body error: " ++ Reason}
	end.

encode_send(Socket, {_MsgRecord, _BodyBin}) ->
	ok.

