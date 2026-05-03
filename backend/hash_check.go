package main

import (
	"fmt"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	hash := "$2a$10$eqJRJvB2h0T.qQif3pM0uuDVfCGRI67TE1ipprk0HC5FVxs6Ueswm"
	pin := "1234"
	
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(pin))
	if err != nil {
		fmt.Println("Mismatch!")
	} else {
		fmt.Println("Match!")
	}

	newHash, _ := bcrypt.GenerateFromPassword([]byte(pin), bcrypt.DefaultCost)
	fmt.Println("New hash for 1234:", string(newHash))
}
