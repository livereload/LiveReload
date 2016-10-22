.PHONY: build

build: server

server: main.c ../../livereloadhelper.a ../../livereloadhelper.h Makefile
	$(CC) -o $@ -I../../ main.c ../../livereloadhelper.a -framework Foundation -framework Security
