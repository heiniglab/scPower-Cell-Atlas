package config

import (
	"github.com/spf13/viper"
)

func LoadConfig(path string) error {
	viper.SetConfigFile(path)
	viper.AutomaticEnv()
	return viper.ReadInConfig()
}
