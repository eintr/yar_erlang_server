EBIN_DIR=~/erlang_lib/

sources=yar_msg.erl

beams=$(sources:.erl=.beam)

all: $(beams)

%.beam: %.erl
	erlc $^

install: all
	cp $(beams) $(EBIN_DIR)

clean:
	rm -f $(beams)


