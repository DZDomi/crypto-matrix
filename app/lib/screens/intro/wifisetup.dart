import 'package:crypto_matrix/models/bluetooth.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:crypto_matrix/widgets/wifinetworklist.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';
import 'package:app_settings/app_settings.dart';

class WifiSetupScreen extends StatefulWidget {
  final bool _isIntro;

  WifiSetupScreen({super.key, bool isIntro = true}) : this._isIntro = isIntro;

  @override
  _WifiSetupScreenState createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final BltCom _bltCom = BltCom.instance;

  @override
  Widget build(BuildContext context) {
    var networkListBuilder = StreamBuilder<DeviceConnectionState>(
      stream: this._bltCom.state(),
      builder: (BuildContext context,
          AsyncSnapshot<DeviceConnectionState> snapshot) {
        if (snapshot.hasData) {
          switch (snapshot.data) {
            case DeviceConnectionState.BLUETOOTH_DISABLED:
              return AdaptiveTextButton(
                  child: Text(
                    'Enable bluetooth',
                  ),
                  onPressed: () {
                    _jumpToSettings();
                  });
            case DeviceConnectionState.CONNECTING:
              return AdaptiveTextButton(
                  child: Text('Reconnecting to device...'));
            case DeviceConnectionState.CONNECTED_WITHOUT_WIFI:
              return WifiNetworkListWidget(isIntro: widget._isIntro);
            case DeviceConnectionState.CONNECTED:
              return WifiNetworkListWidget(isIntro: widget._isIntro);
            default:
              return Container();
          }
        } else {
          return Container();
        }
      },
    );
    return AdaptiveScaffold(
        backgroundColor: Colors.white,
        appBar: !widget._isIntro
            ? AdaptiveAppBar(title: Text('Change Wi-Fi'))
            : null,
        body: SafeArea(
            child: Center(
                child: widget._isIntro
                    ? Column(
                        children: <Widget>[
                          Padding(
                              padding: EdgeInsets.only(top: 50, bottom: 30),
                              child: Image.asset('assets/coins/ltc.png')),
                          Text(
                            widget._isIntro ? 'Set up Wi-Fi' : 'Change Wi-Fi',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          Padding(
                              padding: EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 30),
                              child: Text(
                                'Your Crypto Matrix needs internet to load live prices. Choose your Wi-Fi network and enter its password.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                          ),
                          Expanded(child: networkListBuilder)
                        ],
                      )
                    : networkListBuilder)));
  }

  void _jumpToSettings() {
    AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
  }
}
