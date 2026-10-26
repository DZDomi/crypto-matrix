import 'package:crypto_matrix/models/models.dart';

enum DeviceConnectionState {
  BLUETOOTH_DISABLED,
  NOT_CONNECTED,
  CONNECTING,
  CONNECTED_WITHOUT_WIFI,
  CONNECTED
}

enum Style {
  SINGLE_ASSET,
  MULTI_ASSET
}

class Design {
  final Style style;

  Design(this.style);

  Map<String, dynamic> toJson() =>
      {'style': style.index};
}

class Network {
  String ssid;
  int signal = 0;
  String password = '';
  List<String> keyMgmt = [];

  Network(this.ssid, this.signal);

  Network.withPassword(this.ssid, this.password);

  Network.fromJson(Map<String, dynamic> json)
      : ssid = json['ssid'] ?? '',
        signal = json['signal'] ?? 0 {
    keyMgmt = [];
    if (json['keyMgmt'] != null) {
      List<dynamic> mgmt = json['keyMgmt'];
      keyMgmt = mgmt.map<String>((e) => e.toString()).toList();
    }
  }

  Map<String, dynamic> toJson() =>
      {'ssid': ssid, 'signal': signal, 'password': password};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Network &&
          runtimeType == other.runtimeType &&
          ssid == other.ssid;

  @override
  int get hashCode => ssid.hashCode;

  @override
  String toString() {
    return 'Network{ssid: $ssid, signal: $signal}';
  }
}

class BaseResponse {
  final bool success;
  final String? error;
  final dynamic message;

  BaseResponse.fromJson(Map<String, dynamic> json)
      : success = json['success'] ?? false,
        error = json['error'],
        message = json['message'];

  @override
  String toString() {
    return 'BaseResponse{success: $success, error: $error, message: $message}';
  }
}

class WifiNetworksFoundResponse extends BaseResponse {
  Network? network;

  WifiNetworksFoundResponse.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (this.message != null) {
      this.network = Network.fromJson(this.message);
    }
  }
}

class WifiConnectResponse extends BaseResponse {
  bool connected = false;

  WifiConnectResponse.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (this.message != null) {
      this.connected = this.message['connected'] ?? false;
    }
  }

  @override
  String toString() {
    return 'WifiConnectResponse{connected: $connected}';
  }
}

class InfoWifiStateResponse extends BaseResponse {
  bool connected = false;

  InfoWifiStateResponse.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (this.message != null) {
      this.connected = this.message['connected'] ?? false;
    }
  }

  @override
  String toString() {
    return 'InfoWifiStateResponse{connected: $connected}';
  }
}

class SetBrightnessRequest {
  final int brightness;

  SetBrightnessRequest(this.brightness);

  Map<String, dynamic> toJson() => {
        'brightness': brightness,
      };

  @override
  String toString() {
    return 'SetBrightnessRequest{brightness: $brightness}';
  }
}

class SetDesignRequest {
  final Design design;

  SetDesignRequest(this.design);

  Map<String, dynamic> toJson() => {
        'design': design.toJson(),
      };

  @override
  String toString() {
    return 'SetDesignRequest{design: $design}';
  }
}

class UpdateMarketsRequest {
  final List<Market> markets;

  UpdateMarketsRequest(this.markets);

  Map<String, dynamic> toJson() => {
    'markets': markets,
  };

  @override
  String toString() {
    return 'UpdateMarketsRequest{markets: $markets}';
  }
}

class SetTimeframeRequest {
  final TimeFrame timeframe;

  SetTimeframeRequest(this.timeframe);

  Map<String, dynamic> toJson() => {
    'timeframe': timeframe.index,
  };

  @override
  String toString() {
    return 'SetTimeframeRequest{timeframe: $timeframe}';
  }
}
