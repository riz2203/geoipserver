package server

import (
    "net/netip"
    "strings"
)

func CountryForIP(ipStr string) (string, bool) {
    //check if IP is valid
    ip, err := netip.ParseAddr(ipStr)
    if err != nil {
        return "Invalid IP: " + ipStr, false
    }

    db := getDB()
    if db == nil {
        return "DB pointer is nil", false
    }

    record, err := db.Country(ip)
    if err != nil {
        return "Error retrieving country data: " + err.Error(), false
    }
    if !record.HasData() {
        return "No data for IP: " + ipStr, false
    }

    countryName := record.Country.Names.English

    return strings.ToUpper(countryName), true
}

