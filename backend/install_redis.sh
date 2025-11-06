#!/bin/bash

# Install Redis Go client
cd "$(dirname "$0")"
go get github.com/redis/go-redis/v9
go mod tidy

echo "Redis client installed successfully"
