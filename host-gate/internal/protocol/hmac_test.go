package protocol

import (
	"testing"
)

func TestSignAndVerify(t *testing.T) {
	key := []byte("test-key-32-bytes-long-padding!!")
	canonical := "v1:nonce123:1711540800:git:[\"push\"]:cwd::proxy:popup"

	sig := Sign(key, canonical)
	if sig == "" {
		t.Fatal("Sign returned empty string")
	}

	if !Verify(key, canonical, sig) {
		t.Fatal("Verify failed for valid signature")
	}
}

func TestVerifyRejectsWrongKey(t *testing.T) {
	key1 := []byte("key-one-32-bytes-long-padding!!!")
	key2 := []byte("key-two-32-bytes-long-padding!!!")
	canonical := "v1:nonce123:1711540800:git:[\"push\"]:cwd::proxy:popup"

	sig := Sign(key1, canonical)
	if Verify(key2, canonical, sig) {
		t.Fatal("Verify should reject signature made with different key")
	}
}

func TestVerifyRejectsTamperedCanonical(t *testing.T) {
	key := []byte("test-key-32-bytes-long-padding!!")
	canonical := "v1:nonce123:1711540800:git:[\"push\"]:cwd::proxy:popup"

	sig := Sign(key, canonical)
	tampered := "v1:nonce123:1711540800:git:[\"push\",\"--force\"]:cwd::proxy:popup"
	if Verify(key, tampered, sig) {
		t.Fatal("Verify should reject tampered canonical string")
	}
}

func TestVerifyRejectsEmptyHMAC(t *testing.T) {
	key := []byte("test-key-32-bytes-long-padding!!")
	canonical := "v1:nonce123:1711540800:git:[\"push\"]:cwd::proxy:popup"

	if Verify(key, canonical, "") {
		t.Fatal("Verify should reject empty HMAC")
	}
}

func TestCanonicalString(t *testing.T) {
	req := ExecuteRequest{
		Version:   1,
		Nonce:     "test-nonce",
		Timestamp: 1711540800,
		Command:   "git",
		Args:      []string{"push", "origin", "main"},
		Cwd:       "/workspace",
		Execution: "proxy",
		Approval:  "popup",
	}

	canonical := req.CanonicalString()
	expected := `v1:test-nonce:1711540800:git:["push","origin","main"]:/workspace::proxy:popup`
	if canonical != expected {
		t.Fatalf("CanonicalString mismatch:\n  got:  %s\n  want: %s", canonical, expected)
	}
}

func TestCanonicalStringWithHostCwd(t *testing.T) {
	req := ExecuteRequest{
		Version:   1,
		Nonce:     "n",
		Timestamp: 100,
		Command:   "aws",
		Args:      []string{"s3", "ls"},
		Cwd:       "/workspace",
		HostCwd:   "/home/user/project",
		Execution: "proxy",
		Approval:  "popup",
	}

	canonical := req.CanonicalString()
	expected := `v1:n:100:aws:["s3","ls"]:/workspace:/home/user/project:proxy:popup`
	if canonical != expected {
		t.Fatalf("CanonicalString mismatch:\n  got:  %s\n  want: %s", canonical, expected)
	}
}

func TestCanonicalStringEmptyArgs(t *testing.T) {
	req := ExecuteRequest{
		Version:   1,
		Nonce:     "nonce",
		Timestamp: 100,
		Command:   "ls",
		Args:      []string{},
		Cwd:       "/home",
		Execution: "local",
		Approval:  "popup",
	}

	canonical := req.CanonicalString()
	expected := "v1:nonce:100:ls:[]:/home::local:popup"
	if canonical != expected {
		t.Fatalf("CanonicalString mismatch:\n  got:  %s\n  want: %s", canonical, expected)
	}
}
