package server

import (
    "encoding/json"
    "net/http"
    "strings"
    "log"
)

func CheckHandler(w http.ResponseWriter, r *http.Request) {
    var req CheckRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid JSON", http.StatusBadRequest)
        return
    }

    for i := range req.Countries {
        req.Countries[i] = strings.ToUpper(req.Countries[i])
    }

    ipCountry, ok := CountryForIP(req.IP)
    if !ok {
        writeJSON(w, CheckResponse{Match: false})
        log.Printf("IP %s lookup failed: %s", req.IP, ipCountry)
        return
    } else {
        log.Printf("IP %s maps to country %s", req.IP, ipCountry)
    }

    match := false
    for _, c := range req.Countries {
        if c == ipCountry {
            match = true
            log.Printf("IP %s matches country %s in request", req.IP, c)
            break
        }
    }
    if !match { 
        log.Printf("IP %s does not match any of the requested countries: %v", req.IP, req.Countries)
    }    

    writeJSON(w, CheckResponse{Match: match})
}

func writeJSON(w http.ResponseWriter, v any) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(v)
}

