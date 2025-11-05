FROM golang:1.21-alpine AS builder

WORKDIR /app

RUN apk add --no-cache gcc musl-dev zeromq-dev

COPY . .
RUN go mod tidy && go mod download
RUN go build -o main .

FROM alpine:latest
RUN apk add --no-cache zeromq

WORKDIR /app
COPY --from=builder /app/main .

CMD ["./main"]

