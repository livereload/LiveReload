package main

/*
#include <stdint.h>

typedef void (*LRNetwStatusCallback)(int conns);

void update_status(uintptr_t cb, int conns) {
    ((LRNetwStatusCallback)cb)(conns);
}
*/
import "C"

func monitorStatus() {
	stat := srv.Status()
	for {
		C.update_status(C.uintptr_t(callback), C.int(stat.Conns))
		stat = srv.AwaitStatusChange(stat.V)
	}
}
