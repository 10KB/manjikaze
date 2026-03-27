.PHONY: build build-daemon build-client test lint clean

DAEMON_BIN=host-gate-daemon
CLIENT_BIN=host-gate-client

build: build-daemon build-client

build-daemon:
	go build -o bin/$(DAEMON_BIN) ./cmd/host-gate-daemon

build-client:
	GOOS=linux GOARCH=amd64 go build -o bin/$(CLIENT_BIN)-linux-amd64 ./cmd/host-gate-client
	GOOS=linux GOARCH=arm64 go build -o bin/$(CLIENT_BIN)-linux-arm64 ./cmd/host-gate-client

test:
	go test ./... -v -race -cover

lint:
	golangci-lint run ./...

clean:
	rm -rf bin/
