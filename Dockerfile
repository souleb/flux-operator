# Build the operator binary using the Docker's Debian image.
FROM --platform=${BUILDPLATFORM} golang:1.22 AS builder
ARG TARGETOS
ARG TARGETARCH
WORKDIR /workspace

# Copy the Go Modules manifests.
COPY go.mod go.mod
COPY go.sum go.sum

# Cache the Go Modules
RUN go mod download

# Copy the Go sources.
COPY cmd/main.go cmd/main.go
COPY api/ api/
COPY internal/ internal/

# Build the operator binary.
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -a -o flux-operator cmd/main.go

# Run the operator binary using Google's Distroless image.
FROM gcr.io/distroless/static:nonroot
WORKDIR /

# Copy the binary and manifests data.
COPY --from=builder /workspace/flux-operator .
COPY config/data/ /data/

# Run the operator as a non-root user.
USER 65532:65532
ENTRYPOINT ["/flux-operator"]
