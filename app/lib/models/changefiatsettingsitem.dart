import 'dart:convert';

import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:crypto_matrix/widgets/fiatsearch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeFiatSettingsItem extends SettingsItem {
  ChangeFiatSettingsItem(String text) : super(text);

  late BuildContext _context;
  late SetStateCallback _callback;

  @override
  Widget? buildTitle(BuildContext context, SetStateCallback callback) {
    _context = context;
    _callback = callback;
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AdaptiveIconButton(
                padding: EdgeInsets.zero,
                materialIcon: Icon(Icons.attach_money, color: Colors.black),
                cupertinoIcon: Icon(CupertinoIcons.money_dollar,
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
    return FutureBuilder<Asset?>(
      future: _getFiat(),
      builder: (BuildContext context, AsyncSnapshot<Asset?> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Text(snapshot.data!.symbol.toUpperCase());
        } else {
          return Text('');
        }
      },
    );
  }

  Future<Asset?> _getFiat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var fiat = prefs.getString(SharedPreferencesConst.SETTINGS_FIAT);
    if (fiat == null) {
      return null;
    }
    return Asset.fromJson(jsonDecode(fiat));
  }

  @override
  void onTap(BuildContext context) {
    showSearch(context: context, delegate: FiatSearchDelegate(_fiatSelected));
  }

  Future<void> _fiatSelected(Asset selectedFiat) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        SharedPreferencesConst.SETTINGS_FIAT, jsonEncode(selectedFiat));
    _callback(() => Navigator.pop(_context));
  }
}
