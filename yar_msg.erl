-module(yar_msg).

-export([recv_decode/1, encode_send/2]).

-author("牛海青<nhf0424@gmail.com>").

-include("yar_msg.hrl").

recv_decode(Socket) ->
	case gen_tcp:recv(Socket, ?sizeof_yar_msg_hdr) of
		{ok, <<	Id:32/big-unsigned-integer,
				Version:16/big-unsigned-integer,
				?yar_magic_num:32/big-unsigned-integer,
				_Reserved:32/big-unsigned-integer,
				Provider:8/binary-unit:32,
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
											token = Token },
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
			{ok, msgpack_to_yar_msg_body(msgpack:unpack(Rest))};
		_ ->
			{error, "Unknown serializer: " ++ binary_to_list(Type)}
	end.

msgpack_to_yar_msg_body({ok, {List}}) when is_list(List)->
	{_, Id} = lists:keyfind(<<"i">>, 1, List),
	{_, Method} = lists:keyfind(<<"m">>, 1, List),
	{_, Parameter} = lists:keyfind(<<"p">>, 1, List),
	#yar_msg_body{
		id = Id,
		method = Method,
		parameter = Parameter
	}.

encode_send(Socket, {Id, ReturnValue}) ->
	gen_tcp:send(Socket, msg_encode({Id, ReturnValue})).

msg_encode({Id, ReturnValue}) ->
	Bin=pack_body({Id, ReturnValue}),
	Len=byte_size(Bin),
	Provider=yar_provider(),
	<<
		Id:32/big-unsigned-integer,
	%	?yar_version:16/big-unsigned-integer,	% Version
		0:16/big-unsigned-integer,	% Version
		?yar_magic_num:32/big-unsigned-integer,
		0:32/big-unsigned-integer,	% Reserved field
		Provider/binary,
		0:8/unsigned-integer-unit:32,	% Token
		Len:32/big-unsigned-integer,
		Bin/binary
	>>.

pack_body({Id, ReturnValue}) when is_map(ReturnValue)->
	Map = #{"i"=>Id, "s"=>0, "r"=>ReturnValue},
	Data = msgpack:pack(Map, [{format, map}]),
	<<	?yar_body_method_msgpack/binary,
		Data/binary
	>>.

