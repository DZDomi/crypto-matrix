import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'listitem.dart';

typedef SetStateCallback = void Function(VoidCallback);

class SettingsItem implements ListItem {
  final String text;

  SettingsItem(this.text);

  @override
  Widget? buildTitle(BuildContext context, SetStateCallback callback) {
    return null;
  }

  @override
  Widget? buildSubtitle(BuildContext context, SetStateCallback callback) {
    return null;
  }

  @override
  Widget? buildTrailing(BuildContext context, SetStateCallback callback) {
    return null;
  }

  void onTap(BuildContext context) {
    //Do nothing
  }
}
