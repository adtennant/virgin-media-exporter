# Workaround for QEmu bug when building for 32bit platforms on a 64bit host
FROM --platform=$BUILDPLATFORM rust:latest as vendor
WORKDIR /app

COPY ./Cargo.toml Cargo.toml
COPY ./Cargo.lock Cargo.lock

RUN mkdir .cargo && cargo vendor > .cargo/config.toml

FROM rust:latest as builder
WORKDIR /app

COPY ./build-deps.py .

COPY ./Cargo.toml .
COPY ./Cargo.lock .

COPY --from=vendor /app/.cargo .cargo
COPY --from=vendor /app/vendor vendor

RUN apt-get update && apt-get install python-toml
RUN python ./build-deps.py | while read cmd; do \
    $cmd;                                    \
    done

# Without the workaround
# FROM rust:latest as builder

# RUN cargo install cargo-build-deps

# COPY ./Cargo.toml .
# COPY ./Cargo.lock .

# RUN cargo build-deps --release

COPY ./src src
RUN  cargo build --release

FROM debian:buster-slim

COPY ./config config
COPY --from=builder /app/target/release/virgin-media-prometheus-exporter /usr/local/bin

ENTRYPOINT ["./usr/local/bin/virgin-media-prometheus-exporter"]