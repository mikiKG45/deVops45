package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"os"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/exaring/otelpgx"
	"github.com/jackc/pgx/v5/pgxpool"
)

// dbCredentials mirrors the JSON stored in AWS Secrets Manager.
type dbCredentials struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Host     string `json:"host"`
	Port     int    `json:"port"`
	DBName   string `json:"dbname"`
}

// message is one row of the messages table.
type message struct {
	ID   int    `json:"id"`
	Body string `json:"body"`
}

// fetchCredentials reads the DB secret from Secrets Manager.
// The AWS SDK automatically uses the pod's IRSA role — no keys anywhere.
func fetchCredentials(ctx context.Context, secretName string) (*dbCredentials, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, fmt.Errorf("load aws config: %w", err)
	}
	sm := secretsmanager.NewFromConfig(cfg)
	out, err := sm.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{SecretId: &secretName})
	if err != nil {
		return nil, fmt.Errorf("get secret: %w", err)
	}
	var creds dbCredentials
	if err := json.Unmarshal([]byte(*out.SecretString), &creds); err != nil {
		return nil, fmt.Errorf("parse secret json: %w", err)
	}
	return &creds, nil
}

// connectDB fetches credentials and opens a Postgres connection pool.
func connectDB(ctx context.Context) (*pgxpool.Pool, error) {
	secretName := os.Getenv("DB_SECRET_NAME")
	if secretName == "" {
		return nil, fmt.Errorf("DB_SECRET_NAME env var not set")
	}
	creds, err := fetchCredentials(ctx, secretName)
	if err != nil {
		return nil, err
	}
	// url.QueryEscape handles any special chars in the password safely.
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=require",
		url.QueryEscape(creds.Username), url.QueryEscape(creds.Password),
		creds.Host, creds.Port, creds.DBName)
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, err
	}
	cfg.ConnConfig.Tracer = otelpgx.NewTracer() // creates a span for every DB query
	return pgxpool.NewWithConfig(ctx, cfg)

}

// ensureSchema creates the messages table if it doesn't exist.
func ensureSchema(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS messages (
			id         SERIAL PRIMARY KEY,
			body       TEXT NOT NULL,
			created_at TIMESTAMPTZ NOT NULL DEFAULT now()
		)`)
	return err
}

// --- queries (methods on *server, defined in main.go) ---

func (s *server) countMessages(ctx context.Context) (int, error) {
	var n int
	err := s.db.QueryRow(ctx, "SELECT count(*) FROM messages").Scan(&n)
	return n, err
}

func (s *server) insertMessage(ctx context.Context, body string) error {
	_, err := s.db.Exec(ctx, "INSERT INTO messages (body) VALUES ($1)", body)
	return err
}

func (s *server) listMessages(ctx context.Context) ([]message, error) {
	rows, err := s.db.Query(ctx, "SELECT id, body FROM messages ORDER BY id DESC LIMIT 50")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []message
	for rows.Next() {
		var m message
		if err := rows.Scan(&m.ID, &m.Body); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}
