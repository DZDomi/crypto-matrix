# Crypto Matrix App

Companion app for iOS and Android, written in Flutter.

- Finds the Crypto Matrix over Bluetooth LE and sends it Wi-Fi credentials
- Adds, removes and reorders the markets shown on the matrix (up to 8)
- Switches between multi asset and single asset (chart) mode
- Sets brightness, chart timeframe and the preferred fiat currency

Available markets are loaded from the public Binance API, asset names from
CoinGecko. The BLE protocol is implemented in [`lib/util/blt_com.dart`](lib/util/blt_com.dart)
and matches the server in [`services/bluetooth`](../services/bluetooth).

## Running

Requires Flutter 3.47+ (Dart 3.13+).

```sh
flutter pub get
flutter run
```

For iOS, set your own development team in Xcode before running on a device.
Bluetooth is not available in the iOS Simulator, so the app can only find and
control a Crypto Matrix when running on a real device.
