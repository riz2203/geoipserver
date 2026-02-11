package server

type CheckRequest struct {
    Countries []string `json:"countries"`
    IP        string   `json:"ip"`
}

type CheckResponse struct {
    Match bool `json:"match"`
}

