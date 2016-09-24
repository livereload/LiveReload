src=$(wildcard *.go)

.PHONY: clean build

build: networking.a

networking.a: $(src)
	go build -buildmode=c-archive

.SECONDARY: networking.h

clean:
	rm -f networking.a
