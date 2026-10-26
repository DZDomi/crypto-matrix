# Display

Renders market prices and candlestick charts on the LED matrix. It exposes the
`LedMatrixService` from [`proto/services/ledmatrix.proto`](../../proto/services/ledmatrix.proto)
on `unix:///run/crypto-matrix/display.sock`.

## Requirements

- [rpi-rgb-led-matrix](https://github.com/hzeller/rpi-rgb-led-matrix): compile it
  and put `include/*` and `lib/*` into `/usr/local/{include|lib}`
- protobuf and gRPC for C++ (including `protoc` and `grpc_cpp_plugin`)
- CMake 3.16+

The protobuf sources are generated from [`proto/`](../../proto) at build time.

## Build and install

```sh
./install.sh
```

This builds the binary, copies it together with the `fonts` directory to
`/opt/crypto-matrix/display` and restarts `crypto-matrix-display.service`.
