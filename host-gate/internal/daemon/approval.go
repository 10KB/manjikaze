package daemon

import (
	"context"

	"github.com/ewout/host-gate/internal/protocol"
)

// Approver abstracts the desktop approval mechanism for testability.
type Approver interface {
	RequestApproval(ctx context.Context, req protocol.ExecuteRequest, timeout interface{}) (bool, error)
}
