package config

import (
	"os"

	"gopkg.in/yaml.v3"
)

func Load(fpath string) (*Config, error) {
	data, err := os.ReadFile(fpath)
	if err != nil {
		return nil, err
	}

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}

	return &cfg, nil
}
