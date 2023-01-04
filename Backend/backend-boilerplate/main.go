package main

import (
	"backend-boilerplate/controllers"
	"backend-boilerplate/models"

	"github.com/gin-gonic/gin"
)

func main() {
	// Setting up default router defined in gin
	r := gin.Default()

	// Connecting to database
	models.ConnectDatabase()

	// Routes
	r.GET("/books", controllers.FindBooks)
	r.POST("/books", controllers.CreateBook)
	r.GET("/books/:id", controllers.FindBook)
	r.PATCH("/books/:id", controllers.UpdateBook)
	r.DELETE("/books/:id", controllers.DeleteBook)

	// Run the server
	err := r.Run()
	if err != nil {
		return
	}
}
