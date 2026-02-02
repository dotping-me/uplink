package steps

import "github.com/dotping-me/uplink/internal/system"

type IPLinkStep struct {
	AP string
	IP string
}

func (s *IPLinkStep) Name() string {
	return "IP Linkage to AP"
}

// Assigns IP to the interface
func (s *IPLinkStep) Up() error {
	// NOTE: Normally hostapd will bring up the interface, so no need to do it here
	return system.Run("ip", "addr", "add", s.IP, "dev", s.AP)
}

// Brings the interface down and unassigns IP
func (s *IPLinkStep) Down() error {
	if err := system.Run("ip", "link", "set", s.AP, "down"); err != nil {
		return err
	}

	return system.Run("ip", "addr", "flush", "dev", s.AP)
}
