package server

import (
    "log"
    "os"
    "sync/atomic"
    "time"

    "github.com/oschwald/geoip2-golang/v2"
)

var dbPtr atomic.Pointer[geoip2.Reader]
var lastModTime atomic.Pointer[time.Time]

func LoadDB(path string) error {
    db, err := geoip2.Open(path)
    if err != nil {
        return err
    }
    dbPtr.Store(db)

    info, err := os.Stat(path)
    if err == nil {
        t := info.ModTime()
        lastModTime.Store(&t)
    }

    return nil
}

func StartAutoReload(path string, timeout time.Duration) {
    go func() {
        for {
            time.Sleep(timeout)

            info, err := os.Stat(path)
            if err != nil {
                log.Printf("GeoIP stat failed: %v", err)
                continue
            }

            prev := lastModTime.Load()
            if prev != nil && !info.ModTime().After(*prev) {
                log.Printf("GeoIP DB not modified since last load, skipping reload")
                continue
            }

            newDB, err := geoip2.Open(path)
            if err != nil {
                log.Printf("GeoIP reload failed: %v", err)
                continue
            }

            oldDB := dbPtr.Swap(newDB)
            if oldDB != nil {
                oldDB.Close()
            }

            t := info.ModTime()
            lastModTime.Store(&t)

            log.Printf("GeoIP DB reloaded from %s", path)
        }
    }()
}

func getDB() *geoip2.Reader {
    return dbPtr.Load()
}

