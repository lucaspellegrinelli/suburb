# Use the official Gleam image
FROM ghcr.io/gleam-lang/gleam:v1.2.1-erlang-alpine

# Install build dependencies
RUN apk add --no-cache gcc g++ make

# Add project code
COPY . /build/

# Compile the project
RUN cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build

# Run the server
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run", "host"]
