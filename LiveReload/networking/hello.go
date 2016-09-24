package main

import "C"

//export HelloWorld
func HelloWorld(v int) int {
	return v + 42
}

func main() {
}
