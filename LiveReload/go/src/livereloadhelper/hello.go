package main

//go:generate go-bindata -prefix res/ res

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
	srv.LiveReloadJS = MustAsset("livereload.js")
	srv.Start()
}

func main() {
}
