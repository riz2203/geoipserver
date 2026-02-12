
# **📘 README.md (Final Integrated Version)**

```markdown
# GeoIPServer

GeoIPServer is a high‑performance IP‑to‑country validation service that exposes both:

- 🌐 **HTTP REST API**
- 🔌 **gRPC API**

The service determines whether a given IP address belongs to one of a list of allowed countries using the **MaxMind GeoLite2 Country** database.

---

## 📌 Features

- HTTP and gRPC support  
- Fast IP → Country lookup using MaxMind GeoLite2  
- Returns whether the IP is in an allowed country list  
- Lightweight and production‑ready  
- Easy to containerize and deploy  
- Kubernetes + KinD support for local clusters  

---

## 📦 Requirements

The service provides an HTTP‑based API that receives:

- An **IP address**
- A **list of allowed countries**

It returns whether the IP belongs to one of the allowed countries.

To enable this, you must download the **MaxMind GeoLite2 Country** database:

👉 https://dev.maxmind.com/geoip/geoip2/geolite2/

You must create a free MaxMind account to download the database.

---

# 🚀 Quickstart

This Quickstart helps you run GeoIPServer locally in under a minute.

### **1️⃣ Install Dependencies**

- Go 1.20+
- protoc + Go plugins:
  ```bash
  go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
  go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
  ```
- MaxMind GeoLite2 Country database credentials:
  - `MAXMIND_ACCOUNT_ID`
  - `MAXMIND_LICENSE_KEY`

---

### **2️⃣ Clone and Build**

```bash
git clone https://github.com/riz2203/geoipserver.git
cd geoipserver
make build
```

This automatically:

- Updates the GeoIP database  
- Generates protobuf files  
- Runs tests  
- Builds the binary  

---

### **3️⃣ Run the Server**

```bash
make run
```

Default ports:

| Service | Port |
|--------|------|
| HTTP   | 8080 |
| gRPC   | 50051 |

---

### **4️⃣ Test the API**

#### **HTTP Example**

```bash
curl -X POST http://localhost:8080/v1/check \
  -H "Content-Type: application/json" \
  -d '{"countries":["United States","Canada"],"ip":"9.9.9.9"}'
```

#### **gRPC Example**

```bash
grpcurl -plaintext -d \
  '{"ip":"9.9.9.9","countries":["United States","Canada"]}' \
  localhost:50051 geoipservice.GeoIPService/Check
```

You now have a fully running GeoIP validation service.

---

# 🧩 Architecture Overview

Below is a clean, GitHub‑friendly architecture diagram showing the full request flow.

```
                         ┌──────────────────────────┐
                         │      Client Request       │
                         │  (HTTP or gRPC + JSON)    │
                         └──────────────┬───────────┘
                                        │
                                        ▼
                         ┌──────────────────────────┐
                         │      GeoIPServer         │
                         │  (Go Application Layer)  │
                         └──────────────┬───────────┘
                                        │
             ┌──────────────────────────┼──────────────────────────┐
             │                          │                          │
             ▼                          ▼                          ▼
   ┌────────────────┐        ┌────────────────────┐      ┌────────────────────┐
   │  HTTP Handler  │        │   gRPC Handler      │      │   Validation Logic │
   │  /check, /v1   │        │ GeoIPService.Check │      │  Normalize country │
   │ JSON in/out    │        │ protobuf messages  │      │  Lookup IP → CC    │
   └────────────────┘        └────────────────────┘      │  Compare allowed   │
                                                          └────────────────────┘
                                        │
                                        ▼
                         ┌──────────────────────────┐
                         │ MaxMind GeoLite2 DB      │
                         │ (GeoIP2 Country.mmdb)    │
                         └──────────────────────────┘
                                        │
                                        ▼
                         ┌──────────────────────────┐
                         │   Result (Allowed/Not)   │
                         └──────────────────────────┘
```

This illustrates:

- Dual API interfaces (HTTP + gRPC)  
- Shared validation logic  
- MaxMind DB lookup  
- Final boolean result  

---

# 📜 Protobuf Schema Explained

Your `geoip.proto` file defines the gRPC API contract used by clients and the server.

---

## **Service Definition**

```proto
service GeoIPService {
  rpc Check (GeoIPRequest) returns (GeoIPResponse);
}
```

The service exposes a single RPC method:

- **Check** — validates whether an IP belongs to one of the allowed countries.

---

## **Request Message**

```proto
message GeoIPRequest {
  string ip = 1;
  repeated string countries = 2;
}
```

### Field Breakdown

| Field | Type | Description |
|-------|------|-------------|
| `ip` | string | The IP address to validate |
| `countries` | repeated string | List of allowed countries |

This mirrors the HTTP JSON request body.

---

## **Response Message**

```proto
message GeoIPResponse {
  bool match = 1;
}
```

### Field Breakdown

| Field | Type | Description |
|-------|------|-------------|
| `match` | bool | Whether the IP is in the allowed list |

The response is intentionally minimal — the server returns only a boolean indicator.

---

# 🧰 Important Make Targets

### **Update GeoIP Database**

Requires environment variables:

- `MAXMIND_ACCOUNT_ID`
- `MAXMIND_LICENSE_KEY`

```bash
make update-geoip-db
```

Downloads the latest GeoLite2 Country DB into `data/`.

---

### **Generate Protobuf Files**

```bash
make proto
```

Generates Go + gRPC bindings into `pb/`.

---

### **Run Tests**

```bash
make test
```

Runs all Go tests.

---

### **Build the Application**

```bash
make build
```

This performs:

1. `update-geoip-db`
2. `proto`
3. `test`
4. Builds the Go binary:

Output: `./geoipserver`

---

### **Run the Server Locally**

```bash
make run
```

Starts the server using the local GeoIP database.

---

### **Clean Build Artifacts**

```bash
make clean
```

Removes binary + protobuf output.

---

# 🐳 Docker Build

```bash
docker build -t geoipserver:latest .
```

---

# ☸️ Kubernetes + KinD Deployment

The Makefile includes a full KinD workflow.

### **Create KinD Cluster**

```bash
make cluster
```

### **Build Docker Image for KinD**

```bash
make build_k8s
```

### **Load Image Into KinD**

```bash
make load
```

### **Deploy Kubernetes Resources**

```bash
make deploy
```

### **Check Status**

```bash
make status
```

### **Tail Logs**

```bash
make logs
```

### **Restart Deployment**

```bash
make restart
```

---

# 🔄 Full KinD Setup (Cluster + Build + Deploy)

```bash
make setup
```

This performs:

1. Build binary  
2. Create KinD cluster  
3. Build Docker image  
4. Load into KinD  
5. Deploy Kubernetes manifests  
6. Show status  

---

# 🧪 Test Endpoints Inside KinD

### **HTTP Tests**

```bash
make test-http
```

### **gRPC Tests**

```bash
make test-grpc
```
