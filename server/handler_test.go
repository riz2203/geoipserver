package server

import (
	"testing"
	"net/http"
	"net/http/httptest"
	"strings"
)

func TestCheckHandler_InvalidJSON(t *testing.T) {
	r := httptest.NewRequest("POST", "/check", strings.NewReader("not-json"))
	w := httptest.NewRecorder()
	CheckHandler(w, r)
	if w.Code != http.StatusBadRequest {
		t.Errorf("Expected 400 for invalid JSON, got %d", w.Code)
	}
       t.Log("TestCheckHandler_InvalidJSON passed: 400 returned for invalid JSON")
}

func TestWriteJSON(t *testing.T) {
	w := httptest.NewRecorder()
	writeJSON(w, CheckResponse{Match: true})
	if w.Code != http.StatusOK {
		t.Errorf("Expected 200, got %d", w.Code)
	}
       t.Log("TestWriteJSON passed: 200 returned for valid JSON")
}

func TestCheckHandler_EmptyBody(t *testing.T) {
	r := httptest.NewRequest("POST", "/check", strings.NewReader(""))
	w := httptest.NewRecorder()
	CheckHandler(w, r)
	if w.Code != http.StatusBadRequest {
		t.Errorf("Expected 400 for empty body, got %d", w.Code)
	}
       t.Log("TestCheckHandler_EmptyBody passed: 400 returned for empty body")
}

func TestCheckHandler_MissingFields(t *testing.T) {
	// Missing countries field
	r := httptest.NewRequest("POST", "/check", strings.NewReader(`{"ip":"1.2.3.4"}`))
	w := httptest.NewRecorder()
	CheckHandler(w, r)
       t.Log("TestCheckHandler_MissingFields passed: handled missing countries field")
	if w.Code != http.StatusOK {
		t.Errorf("Expected 200 for missing countries, got %d", w.Code)
	}
}

func TestWriteJSON_NilValue(t *testing.T) {
	w := httptest.NewRecorder()
	writeJSON(w, nil)
	if w.Code != http.StatusOK {
		t.Errorf("Expected 200 for nil value, got %d", w.Code)
	}
}
