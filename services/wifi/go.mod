module github.com/DZDomi/crypto-matrix/services/wifi

go 1.27

require (
	github.com/DZDomi/crypto-matrix/proto v0.0.0-00010101000000-000000000000
	github.com/joho/godotenv v1.5.1
	github.com/mark2b/wpa-connect v1.5.1
	github.com/sirupsen/logrus v1.10.2
	google.golang.org/grpc v1.84.0
)

require (
	github.com/godbus/dbus v4.1.0+incompatible // indirect
	github.com/op/go-logging v0.0.0-20160315200505-970db520ece7 // indirect
	golang.org/x/net v0.61.0 // indirect
	golang.org/x/sys v0.49.0 // indirect
	golang.org/x/text v0.43.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20261026165753-2ffab32bce7e // indirect
	google.golang.org/protobuf v1.36.12 // indirect
)

replace github.com/DZDomi/crypto-matrix/proto => ../../proto
