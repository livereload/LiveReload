src=$(wildcard *.go)

.PHONY: clean all test build build-example run-example

all: test build


##### build

build:
	go build -buildmode=c-archive

.SECONDARY: livereloadhelper.h


##### example

build-example: build
	$(MAKE) -C cmd/livereloadcserver build

run-example: build-example
	cmd/livereloadcserver/server


##### others

test:
	go test

clean:
	rm -f livereloadhelper.a
	rm -f livereloadhelper.h
