package main

import (
    "log"
    "net"
    "net/http"
    "time"
    "geoipserver/pb"
    "geoipserver/server"
    "google.golang.org/grpc"
    "google.golang.org/grpc/reflection"
)

func main() {
    // Define the path to the GeoIP database
    dbPath := "data/GeoLite2-Country.mmdb"
    timeout:= 1 * 24 * time.Hour // check for updates every 24 hours

    // Load the GeoIP database at startup
    err := server.LoadDB(dbPath)
    if err != nil {
        log.Fatalf("failed to load DB: %v", err)
    } else {
        log.Printf("DB loaded successfully from %s", dbPath)
    }

    // Start the auto-reload goroutine to check for DB updates
    server.StartAutoReload(dbPath, timeout)

    // Set up HTTP handler for /check endpoint
    mux := http.NewServeMux()
    mux.HandleFunc("/check", server.CheckHandler) //default API endpoint without versioning
    mux.HandleFunc("/v1/check", server.CheckHandler) // version v1 of the API

    // Start gRPC server on port 50051
    go func() {
        listener, err := net.Listen("tcp", ":50051")
        if err != nil {
            log.Fatalf("gRPC listener error: %v", err)
        }
        grpcServer := grpc.NewServer()
        pb.RegisterGeoIPServiceServer(grpcServer, &server.GeoIPServiceImpl{})
        reflection.Register(grpcServer)
        log.Println("gRPC server running on :50051")
        if err := grpcServer.Serve(listener); err != nil {
            log.Fatalf("gRPC server error: %v", err)
        }
    }()

    log.Println("Server running on http://localhost:8080")
    err = http.ListenAndServe(":8080", mux)
    if err != nil {
        log.Fatalf("server error: %v", err)
    }
}

