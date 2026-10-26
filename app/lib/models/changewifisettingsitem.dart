import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:crypto_matrix/screens/intro/wifisetup.dart';
import 'package:crypto_matrix/util.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';

class ChangeWifiSettingsItem extends SettingsItem {
  final BltCom _bltCom = BltCom.instance;

  ChangeWifiSettingsItem(String text) : super(text);

  @override
  Widget? buildTitle(BuildContext context, SetStateCallback callback) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AdaptiveIconButton(
                padding: EdgeInsets.zero,
                materialIcon: Icon(Icons.wifi, color: Colors.black),
                cupertinoIcon:
                    Icon(CupertinoIcons.wifi, color: Colors.black, size: 28),
              ),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            ],
          ),
        ]);
  }

  @override
  void onTap(BuildContext context) {
    if (!this._bltCom.isConnectedToDevice()) {
      Util.showNotConnectedAlert(context);
      return;
    }
    Navigator.push(
      context,
      adaptivePageRoute(
        builder: (context) => WifiSetupScreen(isIntro: false),
      ),
    );
  }
}
