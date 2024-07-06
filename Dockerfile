FROM ghcr.io/gleam-lang/gleam:v1.2.1-erlang-alpine

ENV PORT=8080
ENV API_SECRET=yoursecrettoken
ENV DATABASE_PATH=/app/suburb.db

RUN apk add --no-cache gcc g++ make

COPY . /build/

RUN cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build

EXPOSE $PORT

WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run", "host"]
