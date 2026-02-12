# Multi-stage build: build the Go binary, then copy into a small runtime image
FROM golang:1.24-alpine AS builder

WORKDIR /src

# cache deps
COPY go.mod go.sum ./
RUN apk add --no-cache git ca-certificates && update-ca-certificates || true
RUN go mod download

# copy sources
COPY . .

# build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/geoipserver ./main.go

# Final image
FROM alpine:3.18
RUN addgroup -S app && adduser -S -G app app

# Copy binary and data directory
COPY --from=builder /app/geoipserver /usr/local/bin/geoipserver
COPY --from=builder /src/data /app/data

RUN chown -R app:app /app
WORKDIR /app
USER app

EXPOSE 8080
EXPOSE 50051
ENTRYPOINT ["/usr/local/bin/geoipserver"]
