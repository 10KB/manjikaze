package protocol

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
)

func Sign(key []byte, canonical string) string {
	mac := hmac.New(sha256.New, key)
	mac.Write([]byte(canonical))
	return hex.EncodeToString(mac.Sum(nil))
}

func Verify(key []byte, canonical string, providedHMAC string) bool {
	expected := Sign(key, canonical)
	return hmac.Equal([]byte(expected), []byte(providedHMAC))
}
