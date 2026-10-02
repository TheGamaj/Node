package main

import (
	"log"

	"github.com/TheGamaj/Node/internal/certutil"
	appconfig "github.com/TheGamaj/Node/internal/config"
	"github.com/TheGamaj/Node/internal/node"
)

func main() {
	settings := appconfig.Load()

	if err := certutil.EnsureServerCertificate(settings.SSLCertFile, settings.SSLKeyFile); err != nil {
		log.Fatalf("failed to prepare TLS certificate: %v", err)
	}

	server, err := node.New(settings)
	if err != nil {
		log.Fatalf("failed to initialize node service: %v", err)
	}

	log.Printf("Node gRPC service running on %s:%d", settings.ServiceHost, settings.ServicePort)
	if err := server.ListenAndServeGRPC(); err != nil {
		log.Fatal(err)
	}
}
