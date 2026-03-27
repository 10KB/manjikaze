package daemon

import (
	"sync"
	"time"
)

type ReplayGuard struct {
	mu     sync.Mutex
	seen   map[string]time.Time
	maxAge time.Duration
}

func NewReplayGuard(maxAge time.Duration) *ReplayGuard {
	rg := &ReplayGuard{
		seen:   make(map[string]time.Time),
		maxAge: maxAge,
	}
	go rg.pruneLoop()
	return rg
}

func (rg *ReplayGuard) Check(nonce string, timestamp int64) bool {
	rg.mu.Lock()
	defer rg.mu.Unlock()

	now := time.Now().Unix()
	diff := now - timestamp
	if diff < 0 {
		diff = -diff
	}
	if diff > int64(rg.maxAge.Seconds()) {
		return false
	}

	if _, exists := rg.seen[nonce]; exists {
		return false
	}

	rg.seen[nonce] = time.Now()
	return true
}

func (rg *ReplayGuard) pruneLoop() {
	ticker := time.NewTicker(60 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		rg.mu.Lock()
		cutoff := time.Now().Add(-rg.maxAge)
		for nonce, t := range rg.seen {
			if t.Before(cutoff) {
				delete(rg.seen, nonce)
			}
		}
		rg.mu.Unlock()
	}
}
