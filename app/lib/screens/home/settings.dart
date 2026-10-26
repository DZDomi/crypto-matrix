import 'package:crypto_matrix/models/brightnesssettingsitem.dart';
import 'package:crypto_matrix/models/changefiatsettingsitem.dart';
import 'package:crypto_matrix/models/changetimeframesettingsitem.dart';
import 'package:crypto_matrix/models/changewifisettingsitem.dart';
import 'package:crypto_matrix/models/forgetdevicesettingsitem.dart';
import 'package:crypto_matrix/models/settingsitem.dart';
import 'package:crypto_matrix/models/settingsitemgroup.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';

class SettingsScreen extends StatefulWidget {
  final String title;
  final List<SettingsItemGroup> _settings = [];

  SettingsScreen({super.key, required this.title}) {
    List<SettingsItem> generalSettings = [];
    List<SettingsItem> deviceSettings = [];

    generalSettings.add(ChangeFiatSettingsItem("Change Fiat"));
    generalSettings.add(ChangeTimeframeSettingsItem("Change Timeframe"));

    deviceSettings.add(BrightnessSettingsItem("Brightness"));
    deviceSettings.add(ChangeWifiSettingsItem("Change Wi-Fi"));
    deviceSettings.add(ForgetDeviceSettingsItem("Forget Device"));

    this._settings.add(SettingsItemGroup("General", generalSettings));
    this._settings.add(SettingsItemGroup("Device", deviceSettings));
  }

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          // automaticallyImplyLeading: false,
          title: Text(widget.title),
        ),
        body: Material(
          child: ListView.builder(
              itemCount: widget._settings.length,
              itemBuilder: (context, index) {
                final SettingsItemGroup item = widget._settings[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  // tileColor: Colors.white,
                  title: item.buildTitle(context, setState),
                  subtitle: item.buildSubtitle(context, setState),
                );
              }),
        ));
  }
}
