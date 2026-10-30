package protocol

import (
	"testing"
)

func TestValidateHappyPath(t *testing.T) {
	req := ExecuteRequest{
		Version:   1,
		Nonce:     "test-nonce",
		Timestamp: 1711540800,
		Command:   "git",
		Args:      []string{"push"},
		Cwd:       "/workspace",
		Execution: "proxy",
		Approval:  "popup",
		HMAC:      "abc123",
	}
	if err := req.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateRejectsWrongVersion(t *testing.T) {
	req := ExecuteRequest{Version: 2, Nonce: "n", Timestamp: 1, Command: "c", Cwd: "/", Execution: "proxy", Approval: "popup", HMAC: "h"}
	if err := req.Validate(); err == nil {
		t.Fatal("expected error for version 2")
	}
}

func TestValidateRejectsEmptyCommand(t *testing.T) {
	req := ExecuteRequest{Version: 1, Nonce: "n", Timestamp: 1, Command: "", Cwd: "/", Execution: "proxy", Approval: "popup", HMAC: "h"}
	if err := req.Validate(); err == nil {
		t.Fatal("expected error for empty command")
	}
}

func TestValidateRejectsInvalidExecution(t *testing.T) {
	req := ExecuteRequest{Version: 1, Nonce: "n", Timestamp: 1, Command: "c", Cwd: "/", Execution: "invalid", Approval: "popup", HMAC: "h"}
	if err := req.Validate(); err == nil {
		t.Fatal("expected error for invalid execution mode")
	}
}

func TestValidateAcceptsNoneApproval(t *testing.T) {
	req := ExecuteRequest{Version: 1, Nonce: "n", Timestamp: 1, Command: "c", Cwd: "/", Execution: "proxy", Approval: "none", HMAC: "h"}
	if err := req.Validate(); err != nil {
		t.Fatalf("unexpected error for approval=none: %v", err)
	}
}

func TestValidateRejectsInvalidApproval(t *testing.T) {
	req := ExecuteRequest{Version: 1, Nonce: "n", Timestamp: 1, Command: "c", Cwd: "/", Execution: "proxy", Approval: "invalid", HMAC: "h"}
	if err := req.Validate(); err == nil {
		t.Fatal("expected error for invalid approval mode")
	}
}

func TestValidateRejectsEmptyHMAC(t *testing.T) {
	req := ExecuteRequest{Version: 1, Nonce: "n", Timestamp: 1, Command: "c", Cwd: "/", Execution: "proxy", Approval: "popup", HMAC: ""}
	if err := req.Validate(); err == nil {
		t.Fatal("expected error for empty hmac")
	}
}
