FROM golang:1.22-bullseye

WORKDIR /app

# Install ZeroMQ dependencies
RUN apt-get update && apt-get install -y \
    libzmq3-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY reference/go/go.mod ./
RUN go mod download

COPY reference/go/ .

RUN go build -o main .

CMD ["./main"]
