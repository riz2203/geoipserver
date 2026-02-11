package server

import (
	"context"
	"geoipserver/pb"
	"log"
	"strings"
)

// GeoIPServiceImpl implements the geoipservice.GeoIPService interface
type GeoIPServiceImpl struct {
	pb.UnimplementedGeoIPServiceServer
}

// Check implements geoipservice.GeoIPService/Check
func (s *GeoIPServiceImpl) Check(ctx context.Context, req *pb.CheckRequest) (*pb.CheckResponse, error) {
	// Normalize countries to uppercase
	for i := range req.Countries {
		req.Countries[i] = strings.ToUpper(req.Countries[i])
	}

	// Look up the IP address
	ipCountry, ok := CountryForIP(req.Ip)
	if !ok {
		log.Printf("IP %s lookup failed: %s", req.Ip, ipCountry)
		return &pb.CheckResponse{Match: false}, nil
	}

	log.Printf("IP %s maps to country %s", req.Ip, ipCountry)

	// Check if the IP's country matches any of the requested countries
	match := false
	for _, c := range req.Countries {
		if c == ipCountry {
			match = true
			log.Printf("IP %s matches country %s in request", req.Ip, c)
			break
		}
	}

	if !match {
		log.Printf("IP %s does not match any of the requested countries: %v", req.Ip, req.Countries)
	}

	return &pb.CheckResponse{Match: match}, nil
}
