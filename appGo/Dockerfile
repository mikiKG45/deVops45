# --- Build stage ---
FROM golang:1.27-alpine AS build
WORKDIR /src

# Dependencies first: this layer is cached until go.mod/go.sum change,
# so code-only edits don't re-download every module.
COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /app .

# --- Runtime stage ---
FROM gcr.io/distroless/static:nonroot
COPY --from=build /app /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
