package database

import (
	"context"
	"fmt"
	"restAPI/internal/app/models"

	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/spf13/viper"
)

func NewConnection() (*pgxpool.Pool, error) {
	connectionString := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s",
		viper.GetString("DB_HOST"),
		viper.GetInt("DB_PORT"),
		viper.GetString("DB_USER"),
		viper.GetString("DB_PASSWORD"),
		viper.GetString("DB_NAME"),
	)
	return pgxpool.Connect(context.Background(), connectionString)
}

func SaveUser(user models.User) error {
	db, err := NewConnection()
	if err != nil {
		return err
	}
	defer db.Close()

	query := `INSERT INTO users (username, password) VALUES ($1, $2)`

	_, err = db.Exec(context.Background(), query, user.Username, user.Password)
	return err
}

func GetUserByID(userID string) (models.User, error) {
	db, err := NewConnection()
	if err != nil {
		return models.User{}, err
	}
	defer db.Close()

	query := `SELECT id, username FROM users WHERE id = $1`
	var user models.User
	err = db.QueryRow(context.Background(), query, userID).Scan(&user.ID, &user.Username)

	return user, err
}

func UpdateUser(userID string, user models.User) error {
	db, err := NewConnection()
	if err != nil {
		return err
	}
	defer db.Close()

	query := `UPDATE users SET username = $1, password = $2 WHERE id = $3`
	_, err = db.Exec(context.Background(), query, user.Username, user.Password, userID)

	return err
}

func DeleteUser(userID string) error {
	db, err := NewConnection()
	if err != nil {
		return err
	}
	defer db.Close()

	query := `DELETE FROM users WHERE id = $1`
	_, err = db.Exec(context.Background(), query, userID)

	return err
}
