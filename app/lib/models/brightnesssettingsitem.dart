import 'dart:async';

import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:crypto_matrix/util.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';

class BrightnessSettingsItem extends SettingsItem {
  final BltCom _bltCom = BltCom.instance;

  double _brightness = 50.0;

  // TODO: Cancel timer on return from view
  int _timePassedInMilliseconds = 0;

  BrightnessSettingsItem(String text) : super(text) {
    Timer.periodic(Duration(milliseconds: 100), (_) {
      _timePassedInMilliseconds = _timePassedInMilliseconds + 100;
    });
  }

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
                  if (_timePassedInMilliseconds > 25) {
                    callback(() {
                      _setBrightness(value.round());
                    });
                    _timePassedInMilliseconds = 0;
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
