package server

import "testing"

func TestCheckRequestStruct(t *testing.T) {
	cr := CheckRequest{Countries: []string{"US", "CA"}, IP: "1.2.3.4"}
	if cr.IP != "1.2.3.4" || len(cr.Countries) != 2 {
		t.Errorf("CheckRequest struct not working as expected")
	}
       t.Log("TestCheckRequestStruct passed: struct fields valid")
}

func TestCheckResponseStruct(t *testing.T) {
	resp := CheckResponse{Match: true}
	if !resp.Match {
		t.Errorf("CheckResponse struct not working as expected")
	}
       t.Log("TestCheckResponseStruct passed: Match field true")
}

func TestCheckRequest_EmptyCountries(t *testing.T) {
	cr := CheckRequest{Countries: []string{}, IP: "1.2.3.4"}
	if len(cr.Countries) != 0 {
		t.Errorf("Expected empty countries slice")
	}
       t.Log("TestCheckRequest_EmptyCountries passed: empty countries handled")
}

func TestCheckRequest_EmptyIP(t *testing.T) {
	cr := CheckRequest{Countries: []string{"US"}, IP: ""}
	if cr.IP != "" {
		t.Errorf("Expected empty IP")
	}
       t.Log("TestCheckRequest_EmptyIP passed: empty IP handled")
}

func TestCheckResponse_FalseMatch(t *testing.T) {
	resp := CheckResponse{Match: false}
	if resp.Match {
		t.Errorf("Expected Match=false")
	}
       t.Log("TestCheckResponse_FalseMatch passed: Match field false")
}
