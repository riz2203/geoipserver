# GeoIPServer Design Documentation

## Overview
GeoIPServer is a Go-based microservice that provides country lookup for IP addresses using MaxMind GeoLite2 database. It exposes both HTTP and gRPC APIs for integration with other services.


## gRPC API
### Proto Definition
- `geoip.proto` defines the gRPC service:
  - **Service**: `GeoIPService`
  - **Method**: `Check(CheckRequest) returns (CheckResponse)`
  - **Messages**:
    - `CheckRequest`: Contains `ip` (string) and `countries` (repeated string).
    - `CheckResponse`: Contains `match` (bool).

### Service Implementation
- `pb/geoip_grpc.pb.go` and `pb/geoip.pb.go` are generated from proto.
- `server/` implements the gRPC server logic.
- gRPC server listens on port 50051.
- Handles requests by:
  - Validating input.
  - Looking up country for IP.
  - Checking against provided country list.
  - Returning a boolean flag as a result.

### Integration
- Other services can call gRPC endpoint for fast, typed country lookup.
- Reflection enabled for easy client generation.

## Architecture

- **main.go**: Entry point. Initializes database, starts HTTP and gRPC servers.
- **server/**: Contains core logic:
  - `handler.go`: HTTP handler for /check endpoint.
  - `lookup.go`: IP-to-country lookup logic.
  - `reloader.go`: Database loading and auto-reload.
  - `request.go`: Request/response structs.
  - `grpc.go`: Implements the gRPC server logic, including the GeoIPService interface and request handling for gRPC calls.
- **pb/**: Generated protobuf files for gRPC API.
- **data/**: Contains GeoLite2 database and update scripts.

## Data Flow
1. **Startup**: Loads GeoLite2 database and starts auto-reload goroutine.
2. **HTTP Request**: `/check` or `/v1/check` endpoint receives JSON with IP and country list.
   - Decodes request.
   - Looks up country for IP.
   - Checks if country matches any in list.
   - Returns JSON response.
3. **gRPC Request**: Uses protobuf-defined service for same logic.

## Key Components
- **Database Reload**: Watches for file changes and reloads DB automatically.
- **Proto**: `geoip.proto` defines gRPC service and messages.
- **Makefile**: Handles build, proto generation, test, cluster setup, deployment, MaxMind DB update and clean.

## Error Handling
- Invalid IPs, missing DB, or lookup failures return appropriate error messages and HTTP status codes.

## Testing
- Unit tests for all core logic, including negative and corner cases.
- Tests are run with `make test` and log pass messages.

## Extensibility
- Easily add more endpoints or enrich response data.
- Can swap out database or add caching.

## Deployment
- Docker and Kubernetes manifests provided for containerized deployment.

## Security
- No sensitive data stored.
- Only country lookup, no personal info.

## Future Improvements
- Add rate limiting, metrics, and tracing.
- Support IPv6 and more granular location data.
- Integrate with external update sources for GeoIP DB.
