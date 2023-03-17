package handlers

import (
	"net/http"

	"restAPI/internal/app/models"
	"restAPI/internal/database"

	"github.com/gin-gonic/gin"
)

func CreateUser(c *gin.Context) {
	var user models.User
	err := c.ShouldBindJSON(&user)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Save user to the database
	err = database.SaveUser(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusCreated)
}

func ReadUser(c *gin.Context) {
	userID := c.Param("id")

	user, err := database.GetUserByID(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, user)
}

func UpdateUser(c *gin.Context) {
	userID := c.Param("id")

	var updatedUser models.User
	err := c.ShouldBindJSON(&updatedUser)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = database.UpdateUser(userID, updatedUser)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
		return
	}

	c.Status(http.StatusOK)
}

func DeleteUser(c *gin.Context) {
	userID := c.Param("id")

	err := database.DeleteUser(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete user"})
		return
	}

	c.Status(http.StatusOK)
}

func ProtectedExample(c *gin.Context) {
	// This is an example of a protected route.
	// The GinAuth middleware should be used to protect this route.
	c.JSON(http.StatusOK, gin.H{"message": "This is a protected route"})
}
