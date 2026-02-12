
# Simple Makefile for geoipserver Go project
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

APP_NAME=geoipserver

.PHONY: all build run clean proto


all: build

build: update-geoip-db proto test
	go build -o $(APP_NAME) main.go

run: build
	./$(APP_NAME)

clean: delete
	 rm -f $(APP_NAME)
	 rm -rf pb

proto:
	if [ ! -d pb ]; then \
		mkdir pb; \
	fi
	protoc --go_out=paths=source_relative:pb --go-grpc_out=paths=source_relative:pb geoip.proto
	
test: proto
	go test -v ./...

# -----------------------------------------
# Update GeoIP Database
# -----------------------------------------
update-geoip-db:
	@echo "Updating GeoIP database..."
	cd $(MAKEFILE_DIR) && \
	MAXMIND_ACCOUNT_ID="$(MAXMIND_ACCOUNT_ID)" \
	MAXMIND_LICENSE_KEY="$(MAXMIND_LICENSE_KEY)" \
	GEOIP_DIR="$(MAKEFILE_DIR)data" \
    bash data/geoip_update.sh

# -----------------------------------------
# Configuration for KinD and Kubernetes
# -----------------------------------------
CLUSTER_NAME := geoip
KIND_CONFIG  := kind-config.yaml
IMAGE_NAME   := geoipserver:latest
K8S_YAML     := k8s-geoip.yaml

# -----------------------------------------
# Create KinD Cluster
# -----------------------------------------
cluster:
	kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)

# -----------------------------------------
# Delete KinD Cluster
# -----------------------------------------
delete:
	kind delete cluster --name $(CLUSTER_NAME)

# -----------------------------------------
# Build Docker Image
# -----------------------------------------
build_k8s:
	docker build -t $(IMAGE_NAME) .

# -----------------------------------------
# Load Image Into KinD
# -----------------------------------------
load:
	kind load docker-image $(IMAGE_NAME) --name $(CLUSTER_NAME)

# -----------------------------------------
# Deploy Kubernetes Resources
# -----------------------------------------
deploy:
	kubectl apply -f $(K8S_YAML)

# -----------------------------------------
# Restart Deployment
# -----------------------------------------
restart:
	kubectl rollout restart deployment geoipserver

# -----------------------------------------
# Show Pod + Service Status
# -----------------------------------------
status:
	kubectl get pods -l app=geoipserver
	kubectl get svc geoipserver

# -----------------------------------------
# Tail Logs
# -----------------------------------------
logs:
	kubectl logs -l app=geoipserver -f

# -----------------------------------------
# Test HTTP Endpoint
# -----------------------------------------
test-http:
	curl -X POST http://localhost:30080/check \
		-H "Content-Type: application/json" \
        -d '{"country":"United states, Canada, France, japan","ip":"9.9.9.9"}'

	 curl -X POST http://localhost:30080/v1/check \
	 	-H "Content-Type: application/json" \
	 	-d '{"countries":["England", "United states", "Canada", "france"],"ip":"47.197.90.60"}'

	 curl -X POST http://localhost:30080/check \
	 	-H "Content-Type: application/json" \
	 	-d '{"countries":["United states"],"ip":"47.197.140.150"}'

# -----------------------------------------
# Test gRPC Endpoint
# -----------------------------------------
test-grpc:
	grpcurl -plaintext localhost:30051 list

	grpcurl -plaintext -d \
		'{"ip":"9.9.9.9","countries":["united states","Canada", "japan"]}' \
		localhost:30051 geoipservice.GeoIPService/Check

	grpcurl -plaintext -d \
		'{"ip":"47.197.90.60","countries":["England", "united states","Canada"]}' \
		localhost:30051 geoipservice.GeoIPService/Check

	grpcurl -plaintext -d \
		'{"ip":"47.197.140.150","countries":["united states"]}' \
		localhost:30051 geoipservice.GeoIPService/Check
# -----------------------------------------
# Full Setup (cluster + build + load + deploy)
# -----------------------------------------
setup: build cluster build_k8s load deploy status

