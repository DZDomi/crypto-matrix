import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';

class ForgetDeviceSettingsItem extends SettingsItem {
  final BltCom _bltCom = BltCom.instance;

  ForgetDeviceSettingsItem(String text) : super(text);

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
                materialIcon: Icon(Icons.delete, color: Colors.red),
                cupertinoIcon:
                    Icon(CupertinoIcons.delete, color: Colors.red, size: 28),
              ),
              Text(
                text,
                style: TextStyle(color: Colors.red),
              )
            ],
          ),
        ]);
  }

  @override
  void onTap(BuildContext context) {
    showAdaptiveDialog(
        context: context,
        builder: (context) {
          return AlertDialog.adaptive(
            title: Text("Forget Device"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: 10),
                Text("Are you sure you want to forget this device?"),
              ],
            ),
            actions: <Widget>[
              AdaptiveTextButton(
                  onPressed: () => {Navigator.pop(context)},
                  child: Text("Cancel")),
              AdaptiveTextButton(
                  onPressed: () async {
                    await this._bltCom.forgetDevice();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pushNamedAndRemoveUntil(
                        context, RouteNames.INTRO_BLUETOOTH, (route) => false);
                  },
                  child: Text("Forget",
                      style: TextStyle(color: Colors.red)))
            ],
          );
        });
  }
}
