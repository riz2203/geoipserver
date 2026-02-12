package server

import "testing"

func TestLoadDB_InvalidPath(t *testing.T) {
	err := LoadDB("/invalid/path/to/db.mmdb")
	if err == nil {
		t.Errorf("Expected error for invalid DB path, got nil")
	}
       t.Log("TestLoadDB_InvalidPath passed: error returned as expected")
}

func TestGetDB_Nil(t *testing.T) {
	db := getDB()
	if db != nil {
		t.Errorf("Expected nil DB before loading, got non-nil")
	}
       t.Log("TestGetDB_Nil passed: db is nil as expected")
}

func TestLoadDB_EmptyPath(t *testing.T) {
	err := LoadDB("")
	if err == nil {
		t.Errorf("Expected error for empty DB path, got nil")
	}
       t.Log("TestLoadDB_EmptyPath passed: error returned as expected")
}

