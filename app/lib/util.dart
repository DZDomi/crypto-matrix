import 'package:crypto_matrix/extensions.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';
import 'package:intl/intl.dart';

class Util {
  static String formatExchange(String exchange) {
    String formatted = "";
    exchange.split("-").forEach((element) {
      formatted += element.capitalize();
      formatted += " ";
    });
    formatted = formatted.substring(0, formatted.length - 1);
    return formatted;
  }

  static String formatVolumeOfMarket(Market market) {
    NumberFormat formatter = NumberFormat.compact();
    return formatter.format(double.parse(market.volumeQuote)) + " " + market.pair.quote.symbol.toUpperCase();
  }

  static String formatTimeFrameShort(TimeFrame timeframe) {
    switch (timeframe) {
      case TimeFrame.Minute:
        return "1m";
      case TimeFrame.FiveMinutes:
        return "5m";
      case TimeFrame.ThirtyMinutes:
        return "30m";
      case TimeFrame.Hour:
        return "1h";
      case TimeFrame.SixHours:
        return "6h";
      case TimeFrame.Day:
        return "1d";
      case TimeFrame.Week:
        return "1w";
      case TimeFrame.Month:
        return "1M";
    }
  }

  static String formatTimeFrameLong(TimeFrame timeframe) {
    switch (timeframe) {
      case TimeFrame.Minute:
        return "1 Minute";
      case TimeFrame.FiveMinutes:
        return "5 Minutes";
      case TimeFrame.ThirtyMinutes:
        return "30 Minutes";
      case TimeFrame.Hour:
        return "1 Hour";
      case TimeFrame.SixHours:
        return "6 Hours";
      case TimeFrame.Day:
        return "1 Day";
      case TimeFrame.Week:
        return "1 Week";
      case TimeFrame.Month:
        return "1 Month";
    }
  }

  static bool checkStateAndShowAlert(BuildContext context, BltCom bltCom) {
    if (!bltCom.isConnectedToDevice()) {
      Util.showNotConnectedAlert(context);
      return true;
    }
    if (!bltCom.isDeviceReady()) {
      Util.showNoWifiAlert(context);
      return true;
    }
    return false;
  }

  static void showLoadingDialog(BuildContext context, String title) {
    showAdaptiveDialog(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        title: Text(title),
        content: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10)
            ),
            CircularProgressIndicator.adaptive()
          ]
        ),
      ),
    );
  }

  static void showErrorAlert(BuildContext context, String text) {
    showAdaptiveDialog(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        title: Text('Error'),
        content: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(text)
        ),
        actions: <Widget>[
          AdaptiveDialogAction(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context)
          )
        ],
      ),
    );
  }

  static void showNoWifiAlert(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        title: Text('No Wi-Fi'),
        content: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Crypto Matrix is currently not connected to the internet, please make sure you have a working internet connection')),
        actions: <Widget>[
          AdaptiveDialogAction(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context)
          )
        ],
      ),
    );
  }

  static void showNotConnectedAlert(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        title: Text('Not connected'),
        content: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Crypto Matrix is currently not connected, please wait for the app to reconnect')
        ),
        actions: <Widget>[
          AdaptiveDialogAction(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context)
          )
        ],
      ),
    );
  }
}
