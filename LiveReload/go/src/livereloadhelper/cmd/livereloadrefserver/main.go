package main

import (
	"flag"
	"log"
	"os"
	"os/signal"

	"livereloadhelper/server"
)

var srv server.Server

func main() {
	flag.IntVar(&srv.Port, "p", server.DefaultPort, "TCP port to listen on")
	flag.Parse()

	srv.Start()
	log.Printf("Server is running.")

	go awaitGracefulShutdown()
	go awaitStatusChanges()

	srv.Wait()
}

func awaitGracefulShutdown() {
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, os.Kill)
	<-c
	signal.Stop(c) // force-quit on a repeated signal in case we fail to quit
	log.Printf("Quitting...")
	srv.Stop()
}

func awaitStatusChanges() {
	stat := srv.Status()
	printStatus(stat)
	for {
		stat = srv.AwaitStatusChange(stat.V)
		printStatus(stat)
	}
}

func printStatus(stat server.Status) {
	log.Printf("Status: %+v", stat)
}
