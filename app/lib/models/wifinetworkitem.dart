import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:flutter/material.dart';

import 'bluetooth.dart';
import 'listitem.dart';

class WifiNetworkHeadingItem implements ListItem {
  final String heading;

  WifiNetworkHeadingItem(this.heading);

  @override
  Widget? buildSubtitle(BuildContext context, SetStateCallback callback) => null;

  @override
  Widget? buildTitle(BuildContext context, SetStateCallback callback) {
    return Text(
      this.heading,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  @override
  Widget? buildTrailing(BuildContext context, SetStateCallback callback) {
    return null;
  }
}

class WifiNetworkItem implements ListItem {
  final Network network;

  WifiNetworkItem(this.network);

  @override
  Widget? buildSubtitle(BuildContext context, SetStateCallback callback) => null;

  @override
  Widget? buildTitle(BuildContext context, SetStateCallback callback) =>
      Text(this.network.ssid);

  @override
  Widget? buildTrailing(BuildContext context, SetStateCallback callback) {
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WifiNetworkItem &&
          runtimeType == other.runtimeType &&
          network == other.network;

  @override
  int get hashCode => network.hashCode;
}
