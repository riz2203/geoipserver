package server

import "testing"

func TestCountryForIP_InvalidIP(t *testing.T) {
	country, ok := CountryForIP("not-an-ip")
	if ok {
		t.Errorf("Expected failure for invalid IP, got ok=true, country=%s", country)
	}
       t.Log("TestCountryForIP_InvalidIP passed: error returned for invalid IP")
}

func TestCountryForIP_EmptyIP(t *testing.T) {
	country, ok := CountryForIP("")
	if ok {
		t.Errorf("Expected failure for empty IP, got ok=true, country=%s", country)
	}
       t.Log("TestCountryForIP_EmptyIP passed: error returned for empty IP")
}

func TestCountryForIP_ValidIPButNoDB(t *testing.T) {
	// This test assumes DB is not loaded, so getDB returns nil
	country, ok := CountryForIP("8.8.8.8")
	if ok {
		t.Errorf("Expected failure for valid IP but no DB, got ok=true, country=%s", country)
	}
       t.Log("TestCountryForIP_ValidIPButNoDB passed: error returned for valid IP but no DB")
}
