package config

type Config struct {
	AP   APConfig   `yaml:"ap"`
	DHCP DHCPConfig `yaml:"dhcp"`
}

type APConfig struct {
	Interface string `yaml:"interface"`
	SSID      string `yaml:"ssid"`
	Password  string `yaml:"password"`
	Channel   int    `yaml:"channel"`
}

type DHCPConfig struct {
	Enabled bool   `yaml:"enabled"`
	Range   string `yaml:"range"`
	Lease   string `yaml:"lease"`
}
