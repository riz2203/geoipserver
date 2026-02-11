
# Simple Makefile for geoipserver Go project

APP_NAME=geoipserver

.PHONY: all build run clean proto


all: build

build: proto
	go build -o $(APP_NAME) main.go

run: build
	./$(APP_NAME)

clean:
	 rm -f $(APP_NAME)
	 rm -rf pb

proto:
	if [ ! -d pb ]; then \
		mkdir pb; \
	fi
	protoc --go_out=paths=source_relative:pb --go-grpc_out=paths=source_relative:pb geoip.proto
