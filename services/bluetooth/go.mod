module github.com/DZDomi/crypto-matrix/services/bluetooth

go 1.27

require (
	github.com/DZDomi/crypto-matrix/proto v0.0.0-00010101000000-000000000000
	github.com/godbus/dbus/v5 v5.2.4
	github.com/joho/godotenv v1.5.1
	github.com/muka/go-bluetooth v0.0.0-20240701044517-04c4f09c514e
	github.com/sirupsen/logrus v1.10.2
	google.golang.org/grpc v1.84.0
	google.golang.org/protobuf v1.36.12
)

require (
	github.com/fatih/structs v1.1.0 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	golang.org/x/net v0.61.0 // indirect
	golang.org/x/sys v0.49.0 // indirect
	golang.org/x/text v0.43.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20261026165753-2ffab32bce7e // indirect
)

replace github.com/DZDomi/crypto-matrix/proto => ../../proto
