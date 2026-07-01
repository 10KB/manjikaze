package daemon

import (
	"os"
	"path/filepath"
	"testing"
)

func TestKeyManagerCreatesKeyFile(t *testing.T) {
	dir := t.TempDir()
	keyPath := filepath.Join(dir, "hmac.key")

	km, err := NewKeyManager(keyPath)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(km.Key()) != 32 {
		t.Fatalf("expected 32-byte key, got %d bytes", len(km.Key()))
	}

	data, err := os.ReadFile(keyPath)
	if err != nil {
		t.Fatalf("failed to read key file: %v", err)
	}
	if len(data) != 32 {
		t.Fatalf("key file should be 32 bytes, got %d", len(data))
	}
}

func TestKeyManagerPreservesInode(t *testing.T) {
	dir := t.TempDir()
	keyPath := filepath.Join(dir, "hmac.key")

	// Create initial key
	NewKeyManager(keyPath)
	info1, _ := os.Stat(keyPath)

	// Recreate with same path (simulates daemon restart)
	NewKeyManager(keyPath)
	info2, _ := os.Stat(keyPath)

	if !os.SameFile(info1, info2) {
		t.Fatal("expected same inode after key regeneration (O_TRUNC)")
	}
}

func TestKeyManagerFilePermissions(t *testing.T) {
	dir := t.TempDir()
	keyPath := filepath.Join(dir, "hmac.key")

	NewKeyManager(keyPath)

	info, err := os.Stat(keyPath)
	if err != nil {
		t.Fatalf("stat failed: %v", err)
	}
	perm := info.Mode().Perm()
	if perm != 0600 {
		t.Fatalf("expected 0600 permissions, got %o", perm)
	}
}
