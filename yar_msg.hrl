-ifndef(YAR_MSG_H).
-define(YAR_MSG_H, true).

-define(sizeof_yar_msg_hdr, 82).

-define(yar_magic_num, 16#80DFEC60).
-define(yar_version, 0).
-define(yar_provider_str, <<"Yar Erlang Server 0.1", 0>>).
-define(yar_token, 0).

-define(yar_body_method_msgpack, <<"MSGPACK", 0>>).

-record(yar_msg_hdr, {
    id,
	version,
	provider,
	token
}).

-record(yar_msg_body, {
	id,
	method,
	parameter
}).

yar_provider() ->
	Str = ?yar_provider_str,
	Size = 32-byte_size(Str),
	Pad = binary:copy(<<0>>, Size),
	<<Str/binary, Pad/binary>>.

-endif.

