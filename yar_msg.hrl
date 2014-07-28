-ifndef(YAR_MSG_H).
-define(YAR_MSG_H, true).


-define(sizeof_yar_msg_hdr, 82).
-record(yar_msg_hdr, {
    id,
	version,
	magic_num,
	reserved,
	provider,
	token,
	body_len
}).

-endif.

