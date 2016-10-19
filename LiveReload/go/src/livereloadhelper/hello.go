package main

import "C"

import (
	"livereloadhelper/server"
)

var srv server.Server

//export HelloWorld
func HelloWorld(v int) int {
	return v + 42
}

//export StartServer
func StartServer() {
	srv.Start()
}

func main() {
}
