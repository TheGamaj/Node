package main

import (
	"fmt"
	"os"
	"strings"

	nodev1 "github.com/TheGamaj/Node/internal/proto/node/v1"
	"google.golang.org/protobuf/proto"
)

func main() {
	if len(os.Args) < 2 || os.Args[1] != "unmarshal-only" {
		// full check: filedesc parses lazily inside proto runtime
		fd := nodev1.File_gamaj_node_v1_node_proto
		if fd == nil {
			fmt.Println("FAIL: descriptor is nil")
			os.Exit(1)
		}
		fmt.Println("path:", fd.Path())
	}
	// Round-trip a message to prove wire format works.
	hello := &nodev1.HelloRequest{MasterId: "test", MasterVersion: "is.0.0.1"}
	b, err := proto.Marshal(hello)
	if err != nil {
		fmt.Println("FAIL marshal:", err)
		os.Exit(1)
	}
	back := &nodev1.HelloRequest{}
	if err := proto.Unmarshal(b, back); err != nil {
		fmt.Println("FAIL unmarshal:", err)
		os.Exit(1)
	}
	if back.MasterId != "test" {
		fmt.Println("FAIL roundtrip")
		os.Exit(1)
	}
	_ = strings.TrimSpace
	fmt.Println("MESSAGE ROUNDTRIP OK")
}
