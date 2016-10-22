package main

//go:generate go-bindata -prefix res/ res

/*
typedef void (*LRNetwStatusCallback)(int conns);
*/
import "C"

import (
	"livereloadhelper/server"
)

var srv server.Server

var callback uintptr

//export LRNetwStart
func LRNetwStart(cb uintptr) {
	callback = cb
	srv.LiveReloadJS = MustAsset("livereload.js")
	srv.Start()
	go monitorStatus()
}

//export LRNetwReload
func LRNetwReload(path *C.char, origPath *C.char, overrideURL *C.char, liveCSS bool) {
	srv.SendReloadRequest(server.ReloadRequest{
		Path:        C.GoString(path),
		OrigPath:    C.GoString(origPath),
		OverrideURL: C.GoString(overrideURL),
		LiveCSS:     liveCSS,
	})
}

//export LRNetwWaitExit
func LRNetwWaitExit() {
	srv.Wait()
}

func main() {
}
