package daemon

import (
	"testing"
	"time"
)

func TestReplayGuardAcceptsNewNonce(t *testing.T) {
	rg := NewReplayGuard(30 * time.Second)
	now := time.Now().Unix()

	if !rg.Check("nonce-1", now) {
		t.Fatal("expected first use of nonce to pass")
	}
}

func TestReplayGuardRejectsDuplicateNonce(t *testing.T) {
	rg := NewReplayGuard(30 * time.Second)
	now := time.Now().Unix()

	rg.Check("nonce-1", now)
	if rg.Check("nonce-1", now) {
		t.Fatal("expected second use of same nonce to fail")
	}
}

func TestReplayGuardRejectsOldTimestamp(t *testing.T) {
	rg := NewReplayGuard(30 * time.Second)
	old := time.Now().Unix() - 60

	if rg.Check("nonce-old", old) {
		t.Fatal("expected old timestamp to be rejected")
	}
}

func TestReplayGuardRejectsFutureTimestamp(t *testing.T) {
	rg := NewReplayGuard(30 * time.Second)
	future := time.Now().Unix() + 60

	if rg.Check("nonce-future", future) {
		t.Fatal("expected far-future timestamp to be rejected")
	}
}

func TestReplayGuardAcceptsDifferentNonces(t *testing.T) {
	rg := NewReplayGuard(30 * time.Second)
	now := time.Now().Unix()

	if !rg.Check("nonce-a", now) {
		t.Fatal("expected nonce-a to pass")
	}
	if !rg.Check("nonce-b", now) {
		t.Fatal("expected nonce-b to pass")
	}
}
