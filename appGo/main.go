package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"strconv"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

// Prometheus metrics.
var (
	requestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{Name: "app_requests_total", Help: "Total HTTP requests by path."},
		[]string{"path"},
	)
	messagesTotal = promauto.NewGauge(
		prometheus.GaugeOpts{Name: "app_messages_total", Help: "Number of messages in the database."},
	)
)

var logger = slog.New(slog.NewJSONHandler(os.Stdout, nil))
// Pre-create every path's counter at 0. A labelled series only exists after its
// first Inc(), so Prometheus would first see it already at its final value and
// rate()/increase() would miss that whole first burst of requests.
func init() {
	for _, p := range []string{"/", "/messages", "/api/messages"} {
		requestsTotal.WithLabelValues(p)
	}
}

// server holds shared dependencies (the DB pool).
type server struct {
	db *pgxpool.Pool
}

func main() {
	ctx := context.Background()
	shutdown, err := initTracer(ctx)
	if err != nil {
		logger.Error("tracer init failed", "error", err)
		os.Exit(1)
	}
	defer shutdown(context.Background())

	db, err := connectDB(ctx)
	if err != nil {
		logger.Error("database connection failed", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	if err := ensureSchema(ctx, db); err != nil {
		logger.Error("schema setup failed", "error", err)
		os.Exit(1)
	}
	logger.Info("connected to database")

	s := &server{db: db}

	mux := http.NewServeMux()
	mux.HandleFunc("/", s.handleHome)
	mux.HandleFunc("/messages", s.handleAddMessage)
	mux.HandleFunc("/api/messages", s.handleListMessages)
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
	mux.Handle("/metrics", promhttp.Handler())

	logger.Info("starting server", "addr", ":8080")
	handler := otelhttp.NewHandler(mux, "http.server")
	if err := http.ListenAndServe(":8080", handler); err != nil {

		logger.Error("server failed", "error", err)
		os.Exit(1)
	}
}

// GET / — shows how many messages are stored.
func (s *server) handleHome(w http.ResponseWriter, r *http.Request) {
	requestsTotal.WithLabelValues("/").Inc()
	count, err := s.countMessages(r.Context())
	if err != nil {
		logger.Error("count messages failed", "error", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}
	messagesTotal.Set(float64(count))
	logger.Info("handled home", "messages", count)
	w.Write([]byte("deVops45 demo app — messages stored: " + strconv.Itoa(count) + "\n"))
}

// GET /messages?body=... — inserts a message.
func (s *server) handleAddMessage(w http.ResponseWriter, r *http.Request) {
	requestsTotal.WithLabelValues("/messages").Inc()
	body := r.URL.Query().Get("body")
	if body == "" {
		http.Error(w, "provide ?body=your+message", http.StatusBadRequest)
		return
	}
	if err := s.insertMessage(r.Context(), body); err != nil {
		logger.Error("insert failed", "error", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}
	logger.Info("message added", "body", body)
	w.Write([]byte("added: " + body + "\n"))
}

// GET /api/messages — returns messages as JSON.
func (s *server) handleListMessages(w http.ResponseWriter, r *http.Request) {
	requestsTotal.WithLabelValues("/api/messages").Inc()
	msgs, err := s.listMessages(r.Context())
	if err != nil {
		logger.Error("list failed", "error", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(msgs)
}
