import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:crypto_matrix/util.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeTimeframeSettingsItem extends SettingsItem {
  final BltCom _bltCom = BltCom.instance;

  ChangeTimeframeSettingsItem(String text) : super(text);

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
                materialIcon: Icon(Icons.timeline, color: Colors.black),
                cupertinoIcon: Icon(CupertinoIcons.chart_bar,
                    color: Colors.black, size: 28),
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
  Widget? buildTrailing(BuildContext context, SetStateCallback callback) {
    return FutureBuilder<TimeFrame>(
      future: _getTimeframe(),
      builder: (BuildContext context, AsyncSnapshot<TimeFrame> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Text(Util.formatTimeFrameShort(snapshot.data!));
        } else {
          return Text('');
        }
      },
    );
  }

  Future<TimeFrame> _getTimeframe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return TimeFrame.values[prefs.getInt(SharedPreferencesConst.SETTINGS_TIMEFRAME) ?? TimeFrame.Day.index];
  }

  @override
  void onTap(BuildContext context) {
    if (Util.checkStateAndShowAlert(context, this._bltCom)) {
      return;
    }
    Navigator.pushNamed(context, RouteNames.SETTINGS_TIMEFRAME);//, arguments: new ChangeTimeframeScreenArguments(_itemSelected));
  }

  // void _itemSelected() async {
  //   setState(() => {});
  // }
}
