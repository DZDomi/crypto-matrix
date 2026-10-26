import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:crypto_matrix/util.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';

class BrightnessSettingsItem extends SettingsItem {
  final BltCom _bltCom = BltCom.instance;

  double _brightness = 50.0;

  static const Duration _updateInterval = Duration(milliseconds: 100);
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  BrightnessSettingsItem(String text) : super(text);

  @override
  Widget? buildTitle(BuildContext context, SetStateCallback callback) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(AdaptiveIcons.brightness, color: Colors.black),
              Expanded(
                  child: Slider.adaptive(
                activeColor: Colors.black,
                value: this._brightness,
                onChanged: (double value) {
                  if (!this._bltCom.isConnectedToDevice()) {
                    Util.showNotConnectedAlert(context);
                    return;
                  }
                  callback(() {
                    this._brightness = value;
                  });
                  final now = DateTime.now();
                  if (now.difference(_lastUpdate) >= _updateInterval) {
                    _lastUpdate = now;
                    _setBrightness(value.round());
                  }
                },
                // Always send the final value, it might have been throttled
                onChangeEnd: (double value) {
                  if (this._bltCom.isConnectedToDevice()) {
                    _setBrightness(value.round());
                  }
                },
                min: 0,
                max: 100,
              )),
              Icon(AdaptiveIcons.brightnessSolid, color: Colors.black)
            ],
          )
        ]);
  }

  Future<void> _setBrightness(int percent) async {
    await this._bltCom.setBrightness(percent);
  }
}
