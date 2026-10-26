module github.com/DZDomi/crypto-matrix/services/market-data

go 1.27

require (
	github.com/DZDomi/crypto-matrix/proto v0.0.0-00010101000000-000000000000
	github.com/adshao/go-binance/v2 v2.8.12
	github.com/joho/godotenv v1.5.1
	github.com/sirupsen/logrus v1.10.2
	github.com/stretchr/testify v1.12.1
	google.golang.org/grpc v1.84.0
	google.golang.org/protobuf v1.36.12
)

require (
	github.com/bitly/go-simplejson v0.5.1 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/gorilla/websocket v1.5.3 // indirect
	github.com/jpillora/backoff v1.1.0 // indirect
	github.com/shopspring/decimal v1.6.0 // indirect
	go.yaml.in/yaml/v3 v3.0.5 // indirect
	golang.org/x/net v0.61.0 // indirect
	golang.org/x/sys v0.49.0 // indirect
	golang.org/x/text v0.43.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20261026165753-2ffab32bce7e // indirect
)

replace github.com/DZDomi/crypto-matrix/proto => ../../proto
