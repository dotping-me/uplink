package system

import (
	"log"
	"os/exec"
)

func Run(cmd string, args ...string) error {
	log.Printf("Running Shell Command: %s %v\n", cmd, args)

	c := exec.Command(cmd, args...)
	output, err := c.CombinedOutput()
	if err != nil {
		log.Printf("✗ %s failed: %s!\n", output, err)
	}

	return err
}
