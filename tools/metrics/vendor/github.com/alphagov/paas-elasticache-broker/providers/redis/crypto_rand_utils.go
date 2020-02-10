package redis

import (
	"crypto/rand"
	"math/big"
)

var alpha = []byte("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
var alphaLower = []byte("abcdefghijklmnopqrstuvwxyz")
var numer = []byte("0123456789")

func RandomAlphaNum(length int) string {
	return randChar(1, alpha) + randChar(length-1, append(alpha, numer...))
}

func randChar(length int, chars []byte) string {
	charsLen := big.NewInt(int64(len(chars)))

	password := make([]byte, length)
	for i := 0; i < length; i++ {
		charsIndex, err := rand.Int(rand.Reader, charsLen)
		if err != nil {
			panic(err)
		}
		password[i] = chars[charsIndex.Int64()]
	}
	return string(password)
}
