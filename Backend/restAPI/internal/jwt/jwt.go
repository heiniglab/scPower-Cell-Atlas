package jwt

import (
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/spf13/viper"
)

func GenerateToken(userID string) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(time.Hour * 72).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(viper.GetString("JWT_SECRET")))
}
