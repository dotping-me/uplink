package main

import (
	"log"

	"github.com/dotping-me/uplink/internal/config"
)

func main() {
	cfg, err := config.Load("uplink.yaml")
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Interface: %s", cfg.AP.Interface)
}
