package main

import (
	"log"

	"restAPI/cmd/server"
	"restAPI/internal/config"
	"restAPI/internal/database"
)

func main() {
	if err := config.LoadConfig(".env"); err != nil {
		log.Fatalf("Cannot load config: %v", err)
	}

	db, err := database.NewConnection()
	if err != nil {
		log.Fatalf("Cannot connect to database: %v", err)
	}

	defer db.Close()

	router := server.NewRouter()

	log.Println("Server is running on port 8080")
	log.Fatal(router.Run(":8080"))
}
