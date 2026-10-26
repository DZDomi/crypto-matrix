import 'dart:convert';

import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/screens/home/changetimeframe.dart';
import 'package:crypto_matrix/screens/home/settings.dart';
import 'package:crypto_matrix/screens/intro/bluetoothsetup.dart';
import 'package:crypto_matrix/screens/intro/welcome.dart';
import 'package:crypto_matrix/screens/intro/wifisetup.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home/overview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? fiat = prefs.getString(SharedPreferencesConst.SETTINGS_FIAT);
  // BUSD was the default before Binance discontinued it
  if (fiat == null || Asset.fromJson(jsonDecode(fiat)).symbol == "BUSD") {
    debugPrint('Setting fiat to default value (usdt)');
    await prefs.setString(SharedPreferencesConst.SETTINGS_FIAT, jsonEncode(Fiats.FIATS["USDT"]));
  }

  int? timeframe = prefs.getInt(SharedPreferencesConst.SETTINGS_TIMEFRAME);
  if (timeframe == null) {
    debugPrint('Setting timeframe to default value (1 day)');
    await prefs.setInt(SharedPreferencesConst.SETTINGS_TIMEFRAME, TimeFrame.Day.index);
  }

  BltCom.get(prefs);
  runApp(CryptoMatrix(prefs));
}

class CryptoMatrix extends StatelessWidget {
  final SharedPreferences prefs;

  CryptoMatrix(SharedPreferences p) : this.prefs = p {
    // this.prefs.remove(SharedPreferencesConst.INTRO_FINISHED);
    // this.prefs.remove(SharedPreferencesConst.BLT_COM_DEVICE_UUID);
    // this.prefs.remove(SharedPreferencesConst.SETTINGS_FIAT);
    // this.prefs.remove(SharedPreferencesConst.SETTINGS_TIMEFRAME);
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Crypto Matrix';
    final Widget home = this.prefs.getBool(SharedPreferencesConst.INTRO_FINISHED) ?? false
        ? OverviewScreen(title: "Overview")
        : WelcomeScreen();
    final routes = <String, WidgetBuilder>{
      RouteNames.INTRO_WELCOME: (context) => WelcomeScreen(),
      RouteNames.INTRO_BLUETOOTH: (context) => BluetoothSetupScreen(),
      RouteNames.INTRO_WIFI: (context) => WifiSetupScreen(),
      RouteNames.OVERVIEW: (context) => OverviewScreen(title: 'Overview'),
      RouteNames.SETTINGS: (context) => SettingsScreen(title: 'Settings'),
      RouteNames.SETTINGS_TIMEFRAME: (context) => ChangeTimeframeScreen(title: 'Change timeframe'),
    };

    if (isCupertino) {
      return CupertinoApp(
        title: title,
        home: home,
        routes: routes,
        theme: CupertinoThemeData(brightness: Brightness.light),
        // Material widgets like list tiles and the search are used on iOS too
        localizationsDelegates: [
          DefaultCupertinoLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
      );
    }
    return MaterialApp(
      title: title,
      home: home,
      routes: routes,
      themeMode: ThemeMode.light,
    );
  }
}
