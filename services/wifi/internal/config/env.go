package config

import (
	"os"
	"strconv"
)

func GetEnvAsString(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}

func GetEnvAsBool(key string, fallback bool) bool {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	result, err := strconv.ParseBool(value)
	if err != nil {
		return fallback
	}
	return result
}
