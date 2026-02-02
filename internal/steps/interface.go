package steps

import "github.com/dotping-me/uplink/internal/system"

type InterfaceStep struct {
	Uplink string
	AP     string
}

func (s *InterfaceStep) Name() string {
	return "AP Interface"
}

// Creating the virtual interface
func (s *InterfaceStep) Up() error {
	err := system.Run("iw", "dev", s.Uplink, "interface", "add", s.AP, "type", "__ap")
	if err != nil {
		return err
	}

	return system.Run("nmcli", "dev", "set", s.AP, "managed", "no")
}

func (s *InterfaceStep) Down() error {
	return system.Run(
		"iw", "dev", s.AP, "del", // Deletes the interface
	)
}
