src=$(wildcard *.go)

.PHONY: clean all test build

all: test build


##### build

build: livereloadhelper.a

livereloadhelper.a: $(src)
	go build -buildmode=c-archive

.SECONDARY: livereloadhelper.h


##### others

test:
	go test

clean:
	rm -f livereloadhelper.a
	rm -f livereloadhelper.h
