# Build stage
FROM swift:6.2-jammy AS builder

WORKDIR /build

# Copy package files
COPY Package.swift ./

# Copy source code
COPY Sources ./Sources

# Build the application in release mode
RUN swift build -c release

# Runtime stage
FROM swift:6.2-jammy

WORKDIR /app

# Copy the built executable from builder stage
COPY --from=builder /build/.build/release/Log4MCP ./

# Create a non-root user for running the server
RUN useradd -m -u 1000 log4mcp && chown -R log4mcp:log4mcp /app
USER log4mcp

# Expose the default port
EXPOSE 3000

# Set default environment variables
ENV LOG_LEVEL=INFO
ENV MAX_ENTRIES=1000
ENV VERBOSE=true
ENV LD_LIBRARY_PATH=/usr/lib/swift/linux

# Run the Log4MCP server in TCP mode (default) on port 3000
ENTRYPOINT ["/app/Log4MCP", "--port", "3000", "--host", "0.0.0.0", "--verbose"]
