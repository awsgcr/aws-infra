package main

import (
  "fmt"
  "math/rand"
  "net/http"
  "time"
)

func main() {
  http.HandleFunc("/", HelloServer)
  http.ListenAndServe(":8080", nil)
}

func HelloServer(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintf(w, "Hello!!!!!!!! Prow: %d", Random())
}

func Random() int {
  s := rand.New(rand.NewSource(time.Now().Unix()))
  return s.Intn(100)
}
