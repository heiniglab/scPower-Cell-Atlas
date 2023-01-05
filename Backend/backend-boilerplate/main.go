package main

import (
	"backend-boilerplate/initializers"
	"backend-boilerplate/routers"

	"github.com/gin-gonic/gin"
)

var r *gin.Engine

func init() {
	initializers.LoadEnvVariables()
	initializers.ConnectToDB()
	r = routers.InitRouter()
}

func main() {
	r.Run()
}
