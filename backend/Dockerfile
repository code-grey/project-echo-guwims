# Build stage
FROM golang:1.26-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o server cmd/server/main.go

# Run stage
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/server .
EXPOSE 8080
CMD ["./server"]
