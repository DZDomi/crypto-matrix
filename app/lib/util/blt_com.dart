import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/bluetooth.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as ble;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef NetworkConnectFinished = void Function(bool);
typedef GetMarketStateFinished = void Function(List<Market>);

class BltCom {
  static const Duration LED_TICKER_SCAN_TIMEOUT = Duration(seconds: 30);
  static const Duration LED_TICKER_DEVICE_CONNECT_TIMEOUT = Duration(seconds: 30);
  static const Duration LED_TICKER_WIFI_SCAN_TIMEOUT = Duration(seconds: 10);

  static const String LED_SERVICE_UUID_PREFIX = "d551";
  static const String LED_SERVICE_UUID_SUFFIX = "-fa5e-4343-b3f6-7c77b90d6e0f";

  static const Map<String, String> LED_SERVICE_UUIDS = {
    'info': '1000',
    'ticker': '2000',
    'wifi': '3000'
  };

  static const Map<String, Map<String, String>> LED_SERVICE_CHAR_UUIDS = {
    'info': {
      'get-blt-com-state': '1001',
      'get-market-state': '1002',
      'connected-markets': '1003',
      'get-wifi-state': '1004',
      'disconnect': '1005',
    },
    'ticker': {
      'set-brightness': '2001',
      'set-design': '2002',
      'update-markets': '2003',
      'set-timeframe': '2004',
    },
    'wifi': {
      'start-scan-for-networks': '3001',
      'found-networks': '3002',
      'connect-to-network': '3003',
      'connected-to-network': '3004',
    }
  };

  static const int MAX_MTU = 512;

  final ble.FlutterReactiveBle _ble = ble.FlutterReactiveBle();
  final SharedPreferences _preferences;

  String? _deviceId;
  StreamSubscription<ble.ConnectionStateUpdate>? _connection;
  ble.DeviceConnectionState _connectionState = ble.DeviceConnectionState.disconnected;

  bool _isScanningAllowed = false;
  bool _isScanning = false;

  late final Stream<DeviceConnectionState> _stateStream;
  DeviceConnectionState? _currentState;

  //Singleton to use for the different components
  BltCom._(this._preferences) {
    this._startMonitoringState();
  }

  static BltCom? _instance;

  static BltCom get instance => _instance!;

  static Future<BltCom> get(SharedPreferences prefs) async {
    return _instance ??= BltCom._(prefs);
  }

  void _startMonitoringState() {
    this._ble.statusStream.listen((status) {
      if (status == ble.BleStatus.ready && this._isScanningAllowed) {
        this.startScan();
      }
    });

    this._stateStream = this._state().asBroadcastStream();
    this._stateStream.listen((event) {
      this._currentState = event;
    });
  }

  void setScanningAllowed(bool allowed) {
    this._isScanningAllowed = allowed;
  }

  Stream<DeviceConnectionState> state() async* {
    yield* this._stateStream;
  }

  Stream<DeviceConnectionState> _state() async* {
    bool first = true;
    while (true) {
      if (!first) {
        await Future.delayed(Duration(seconds: 1));
      }
      first = false;
      if (!isOn()) {
        yield DeviceConnectionState.BLUETOOTH_DISABLED;
        continue;
      }
      if (this._isScanning) {
        yield DeviceConnectionState.CONNECTING;
        continue;
      }
      if (this._deviceId == null || this._connectionState != ble.DeviceConnectionState.connected) {
        yield DeviceConnectionState.NOT_CONNECTED;
        continue;
      }
      try {
        BaseResponse baseResponse = BaseResponse.fromJson(await this._read('info', 'get-blt-com-state'));
        if (!baseResponse.success) {
          yield DeviceConnectionState.NOT_CONNECTED;
          continue;
        }
        InfoWifiStateResponse wifiStateResponse = InfoWifiStateResponse.fromJson(await this._read('info', 'get-wifi-state'));
        if (wifiStateResponse.connected) {
          yield DeviceConnectionState.CONNECTED;
        } else {
          yield DeviceConnectionState.CONNECTED_WITHOUT_WIFI;
        }
      } catch (err) {
        yield DeviceConnectionState.NOT_CONNECTED;
      }
    }
  }

  bool isOn() {
    return this._ble.status == ble.BleStatus.ready;
  }

  /// This method should be used to see if we have a working bluetooth
  /// connection to the device
  bool isConnectedToDevice() {
    return this._currentState == DeviceConnectionState.CONNECTED ||
        this._currentState == DeviceConnectionState.CONNECTED_WITHOUT_WIFI;
  }

  /// This method should be used for checking if the device is ready to
  /// do any reasonable action, aka it has internet and is connected with bluetooth
  bool isDeviceReady() {
    return this._currentState == DeviceConnectionState.CONNECTED;
  }

  Future<void> startScan() async {
    if (!isOn()) {
      return;
    }
    // Checking and setting the flag without an await in between is atomic,
    // as Dart runs on a single thread
    if (this._isScanning) {
      debugPrint('Scan in progress, aborting!');
      return;
    }
    this._isScanning = true;

    try {
      if (!await this._requestPermissions()) {
        debugPrint('Bluetooth permissions not granted');
        return;
      }

      var knownDevice = this._preferences.getString(SharedPreferencesConst.BLT_COM_DEVICE_UUID);
      if (knownDevice != null) {
        debugPrint('Found known device in shared prefs: ' + knownDevice);
        await this._connect(knownDevice);
        return;
      }

      debugPrint('Scanning for devices...');
      ble.DiscoveredDevice device;
      try {
        device = await this._ble
            .scanForDevices(withServices: [ble.Uuid.parse(_getUUID(LED_SERVICE_UUIDS['info']!))])
            .first
            .timeout(LED_TICKER_SCAN_TIMEOUT);
      } on TimeoutException {
        debugPrint('No device found');
        return;
      }

      debugPrint('Trying to connect to device: ' + device.name);
      if (await this._connect(device.id)) {
        await this._preferences.setString(SharedPreferencesConst.BLT_COM_DEVICE_UUID, device.id);
      }
    } catch (e) {
      debugPrint('Unable to connect to device: ' + e.toString());
    } finally {
      this._isScanning = false;
    }
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }
    // Location is only needed (and declared) up to Android 11
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses[Permission.bluetoothScan]!.isGranted && statuses[Permission.bluetoothConnect]!.isGranted;
  }

  Future<bool> _connect(String deviceId) async {
    await this._connection?.cancel();
    this._deviceId = deviceId;

    final connected = Completer<bool>();
    this._connection = this._ble
        .connectToDevice(id: deviceId, connectionTimeout: LED_TICKER_DEVICE_CONNECT_TIMEOUT)
        .listen((update) {
      final wasConnected = this._connectionState == ble.DeviceConnectionState.connected;
      this._connectionState = update.connectionState;
      if (update.connectionState == ble.DeviceConnectionState.connected && !connected.isCompleted) {
        connected.complete(true);
      } else if (update.connectionState == ble.DeviceConnectionState.disconnected) {
        if (!connected.isCompleted) {
          connected.complete(false);
        } else if (wasConnected && this._isScanningAllowed) {
          // Try to reconnect, the device drops idle connections
          Future.delayed(Duration(seconds: 1), () => this.startScan());
        }
      }
    }, onError: (Object e) {
      this._connectionState = ble.DeviceConnectionState.disconnected;
      if (!connected.isCompleted) {
        connected.complete(false);
      }
    });

    if (!await connected.future) {
      return false;
    }
    await this._ble.discoverAllServices(deviceId);
    try {
      await this._ble.requestMtu(deviceId: deviceId, mtu: MAX_MTU);
    } catch (e) {
      // Not supported on every platform, the default MTU is used then
    }
    debugPrint('Finished connecting to device!');
    return true;
  }

  //TODO: Error handling
  Stream<Network> getWifiNetworks() async* {
    while (!isConnectedToDevice()) {
      await Future.delayed(Duration(seconds: 1));
    }
    try {
      final events = this._subscribe('wifi', 'found-networks').timeout(LED_TICKER_WIFI_SCAN_TIMEOUT);
      Future.delayed(Duration(milliseconds: 500), () {
        this._read('wifi', 'start-scan-for-networks').catchError((Object e) {
          debugPrint(e.toString());
          return <String, dynamic>{};
        });
      });
      await for (var event in events) {
        var response = WifiNetworksFoundResponse.fromJson(_decode(event));
        if (response.network != null) {
          yield response.network!;
        }
      }
    } on TimeoutException {
      return;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  //TODO: Add mutex
  Future<void> connectToWifi(String ssid, String password, NetworkConnectFinished callback) async {
    if (!isConnectedToDevice()) {
      return;
    }
    late StreamSubscription<List<int>> subscription;
    subscription = this._subscribe('wifi', 'connected-to-network').listen((event) {
      var response = WifiConnectResponse.fromJson(_decode(event));
      subscription.cancel();
      callback(response.connected);
    });
    await this._write('wifi', 'connect-to-network', _prepareRequest(Network.withPassword(ssid, password)));
  }

  Future<bool> updateMarkets(List<Market> markets) async {
    if (!isDeviceReady()) {
      return false;
    }
    try {
      await this._write('ticker', 'update-markets', _prepareRequest(UpdateMarketsRequest(markets)));
    } catch (e) {
      debugPrint(e.toString());
    }
    return true;
  }

  Future<bool> setBrightness(int percent) async {
    if (!isConnectedToDevice()) {
      return false;
    }
    await this._write('ticker', 'set-brightness', _prepareRequest(SetBrightnessRequest(percent)));
    return true;
  }

  Future<bool> setDesign(Design design) async {
    if (!isDeviceReady()) {
      return false;
    }
    await this._write('ticker', 'set-design', _prepareRequest(SetDesignRequest(design)));
    return true;
  }

  Future<bool> setTimeframe(TimeFrame timeframe) async {
    if (!isDeviceReady()) {
      return false;
    }
    await this._write('ticker', 'set-timeframe', _prepareRequest(SetTimeframeRequest(timeframe)));
    return true;
  }

  Future<void> getMarketState(GetMarketStateFinished callback) async {
    if (!isDeviceReady()) {
      return;
    }
    List<Market> markets = [];
    var stream = this._subscribe('info', 'connected-markets').listen((event) {
      BaseResponse baseResponse = BaseResponse.fromJson(_decode(event));
      // TODO: Error handling
      if (!baseResponse.success) {
        return;
      }
      markets.add(Market.fromJson(baseResponse.message));
    });
    await this._read('info', 'get-market-state');
    Future.delayed(Duration(milliseconds: 500), () {
      stream.cancel();
      callback(markets);
    });
  }

  Future<void> forgetDevice() async {
    if (this.isConnectedToDevice()) {
      await this._write('info', 'disconnect', Uint8List.fromList([0]));
    }
    await this._connection?.cancel();
    this._connection = null;
    this._connectionState = ble.DeviceConnectionState.disconnected;
    this._deviceId = null;
    await this._preferences.remove(SharedPreferencesConst.INTRO_FINISHED);
    await this._preferences.remove(SharedPreferencesConst.BLT_COM_DEVICE_UUID);
  }

  Uint8List _prepareRequest(dynamic request) {
    return utf8.encode(jsonEncode(request));
  }

  Map<String, dynamic> _decode(List<int> value) {
    return jsonDecode(utf8.decode(value)) as Map<String, dynamic>;
  }

  ble.QualifiedCharacteristic _characteristic(String service, String characteristic) {
    return ble.QualifiedCharacteristic(
      serviceId: ble.Uuid.parse(_getUUID(LED_SERVICE_UUIDS[service]!)),
      characteristicId: ble.Uuid.parse(_getUUID(LED_SERVICE_CHAR_UUIDS[service]![characteristic]!)),
      deviceId: this._deviceId!,
    );
  }

  Future<Map<String, dynamic>> _read(String service, String characteristic) async {
    return _decode(await this._ble.readCharacteristic(_characteristic(service, characteristic)));
  }

  Future<void> _write(String service, String characteristic, List<int> value) {
    return this._ble.writeCharacteristicWithResponse(_characteristic(service, characteristic), value: value);
  }

  Stream<List<int>> _subscribe(String service, String characteristic) {
    return this._ble.subscribeToCharacteristic(_characteristic(service, characteristic));
  }

  static String _getUUID(String address) {
    return LED_SERVICE_UUID_PREFIX + address + LED_SERVICE_UUID_SUFFIX;
  }
}
