# Multi-stage build for Rust Actix-Web application

# Build stage
ARG RUST_VERSION=1.77
FROM rust:${RUST_VERSION}-slim as builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy Cargo files for dependency caching
COPY Cargo.toml Cargo.lock* ./

# Create a dummy main.rs to build dependencies
RUN mkdir -p src && \
    echo "fn main() {println!(\"Placeholder\");}" > src/main.rs

# Build dependencies (this will be cached)
RUN cargo build --release

# Remove the dummy file and built artifacts
RUN rm -f target/release/deps/app* target/release/app*

# Copy source code
COPY . .

# Build the actual application
RUN cargo build --release

# Runtime stage
FROM debian:bullseye-slim

# Set environment variables
ARG APP_ENV=production
ARG PORT=8080
ENV APP_ENV=${APP_ENV}
ENV PORT=${PORT}
ENV RUST_LOG=${APP_ENV}

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates libssl-dev curl && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/target/release/app /app/app

# Expose the port
EXPOSE ${PORT}

# Set health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:${PORT}/health || exit 1

# Run the application
CMD ["./app"]
