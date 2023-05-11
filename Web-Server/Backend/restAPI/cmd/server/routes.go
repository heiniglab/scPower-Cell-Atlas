package server

import (
	"restAPI/internal/app/handlers"
	"restAPI/internal/app/middleware"

	"github.com/gin-gonic/gin"
)

func NewRouter() *gin.Engine {
	router := gin.Default()

	router.POST("/users", handlers.CreateUser)
	router.GET("/users/:id", handlers.ReadUser)
	router.PUT("/users/:id", handlers.UpdateUser)
	router.DELETE("/users/:id", handlers.DeleteUser)

	// Protected route
	protected := router.Group("/protected")
	protected.Use(middleware.GinAuth())
	protected.GET("/example", handlers.ProtectedExample)

	return router
}
