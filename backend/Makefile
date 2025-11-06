.PHONY: help build run test clean dev install lint fmt

# Default target
help:
	@echo "Available targets:"
	@echo "  make install    - Install dependencies"
	@echo "  make build      - Build the application"
	@echo "  make run        - Run the application"
	@echo "  make dev        - Run with hot reload (requires air)"
	@echo "  make test       - Run tests"
	@echo "  make test-cover - Run tests with coverage"
	@echo "  make lint       - Run linter"
	@echo "  make fmt        - Format code"
	@echo "  make clean      - Clean build artifacts"

# Install dependencies
install:
	go mod download
	go mod tidy

# Build the application
build:
	go build -o bin/server ./cmd/server

# Run the application
run:
	go run cmd/server/main.go

# Run with hot reload
dev:
	air

# Run tests
test:
	go test -v ./...

# Run tests with coverage
test-cover:
	go test -cover ./...
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# Run linter
lint:
	go vet ./...
	golangci-lint run

# Format code
fmt:
	go fmt ./...

# Clean build artifacts
clean:
	rm -rf bin/
	rm -f coverage.out coverage.html
