CC=clang
CFLAGS=-std=c11 -Wall -Werror -Wextra -pedantic
DBG=-g
RLS=-O3
.PHONY: all clean release

all: bin/hexd

bin:
	mkdir bin || true

bin/hexd: bin hexd.c
	$(CC) -o $@ hexd.c $(CFLAGS) $(DBG)

bin/release: bin
	mkdir bin/release || true

bin/release/hexd: bin/release hexd.c
	$(CC) -o $@ hexd.c $(CFLAGS) $(RLS)
	strip $@

release: bin/release/hexd

clean:
	rm -rf bin/*
