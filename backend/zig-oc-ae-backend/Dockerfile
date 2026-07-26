FROM debian:trixie-slim AS builder

ARG ZIG_VERSION=0.16.0
ARG ZIG_URL=https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz

WORKDIR /build
ADD . .

RUN apt-get update && apt-get -y install wget xz-utils && \
    cd /build && \
    wget -O zig.tar.xz "${ZIG_URL}" && \
    tar -xf zig.tar.xz && \
    export PATH="$PATH:$(pwd)/zig-x86_64-linux-${ZIG_VERSION}" && \
    zig init && zig build -Doptimize=ReleaseFast -Dtarget=x86_64-linux-musl && \
    mkdir /app && \
    cp /build/zig-out/bin/oc_ae_backend /app/oc-ae-backend

FROM gcr.io/distroless/static-debian13

WORKDIR /app
COPY --from=builder /app /app

EXPOSE 16500

ENTRYPOINT ["/app/oc-ae-backend"]