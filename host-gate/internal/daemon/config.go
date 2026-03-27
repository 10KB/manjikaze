package daemon

import "time"

type Config struct {
	SocketDir       string
	HostConfigPath  string
	ApprovalTimeout time.Duration
	YubiKeySlot     int
	YubiKeyTimeout  time.Duration
	WorkspaceMaps   []string
}
