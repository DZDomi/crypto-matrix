import 'dart:async';

import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/bluetooth.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';

class BluetoothSetupScreen extends StatefulWidget {
  @override
  _BluetoothSetupScreenState createState() => _BluetoothSetupScreenState();
}

class _BluetoothSetupScreenState extends State<BluetoothSetupScreen> {
  final BltCom _bltCom = BltCom.instance;

  bool _searchButtonPressed = false;

  @override
  void initState() {
    super.initState();
    late StreamSubscription<DeviceConnectionState> stream;
    stream = this._bltCom.state().listen((state) {
      if (!mounted) {
        stream.cancel();
        return;
      }
      if (state == DeviceConnectionState.CONNECTED_WITHOUT_WIFI) {
        stream.cancel();
        Navigator.pushReplacementNamed(context, RouteNames.INTRO_WIFI);
      } else if (state == DeviceConnectionState.CONNECTED) {
        stream.cancel();
        _saveIntro();
        Navigator.pushReplacementNamed(context, RouteNames.OVERVIEW);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Column(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(top: 100, bottom: 30),
                child: Image.asset('assets/coins/eth.png')),
            Text(
              'Connect your matrix',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Padding(
                padding:
                    EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 80),
                child: Text(
                  'Make sure your Crypto Matrix is plugged in and Bluetooth is turned on. Tap search to find it nearby.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                )),
            StreamBuilder<DeviceConnectionState>(
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
                          child: Text('Searching..'));
                    case DeviceConnectionState.NOT_CONNECTED:
                      return AdaptiveTextButton(
                        child: Text('Search'),
                        onPressed:
                            !this._searchButtonPressed ? _findLedWall : null,
                      );
                    default:
                      return Container();
                  }
                } else {
                  return Container();
                }
              },
            )
          ],
        )));
  }

  Future<void> _saveIntro() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SharedPreferencesConst.INTRO_FINISHED, true);
  }

  void _jumpToSettings() {
    AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
  }

  void _findLedWall() {
    this._searchButtonPressed = true;
    this._bltCom.startScan();
  }
}
