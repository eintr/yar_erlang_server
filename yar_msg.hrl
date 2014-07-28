-ifndef(YAR_MSG_H).
-define(YAR_MSG_H, true).

-define(sizeof_yar_msg_hdr, 82).

-define(yar_magic_num, 16#80DFEC60).

-record(yar_msg_hdr, {
    id,
	version,
	provider,
	token,
	body_len
}).

-endif.

