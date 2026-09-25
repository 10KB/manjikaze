package daemon

import (
	crypto_rand "crypto/rand"
	"fmt"
	"os"
)

type KeyManager struct {
	keyPath string
	key     []byte
}

func NewKeyManager(keyPath string) (*KeyManager, error) {
	key := make([]byte, 32)
	if _, err := crypto_rand.Read(key); err != nil {
		return nil, fmt.Errorf("generate key: %w", err)
	}

	// O_TRUNC preserves inode, which is critical for Docker bind mounts
	f, err := os.OpenFile(keyPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0600)
	if err != nil {
		return nil, fmt.Errorf("open key file: %w", err)
	}
	defer f.Close()

	if _, err := f.Write(key); err != nil {
		return nil, fmt.Errorf("write key: %w", err)
	}

	return &KeyManager{keyPath: keyPath, key: key}, nil
}

func (km *KeyManager) Key() []byte {
	return km.key
}
