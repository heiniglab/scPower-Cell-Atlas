package main

import (
	"backend-boilerplate/initializers"
	"backend-boilerplate/models"
)

func init() {
	initializers.LoadEnvVariables()
	initializers.ConnectToDB()
}

func main() {
	initializers.DB.AutoMigrate(&models.Post{})
}
