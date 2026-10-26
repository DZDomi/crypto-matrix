import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/wifinetworkitem.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/listitem.dart';

class WifiNetworkListWidget extends StatefulWidget {
  final bool _isIntro;

  WifiNetworkListWidget({super.key, bool isIntro = true}) : this._isIntro = isIntro;

  @override
  _WifiNetworkListWidgetState createState() => _WifiNetworkListWidgetState();
}

class _WifiNetworkListWidgetState extends State<WifiNetworkListWidget> {
  final BltCom _bltCom = BltCom.instance;

  final WifiNetworkHeadingItem _heading = WifiNetworkHeadingItem("Networks");
  final Set<ListItem> _networks = {};

  @override
  void initState() {
    super.initState();
    this._bltCom.getWifiNetworks().listen((network) {
      setState(() {
        this._networks.add(WifiNetworkItem(network));
      });
    });
  }

  void selectItem(WifiNetworkItem item) async {
    WifiNetworkItem wifiItem = item;

    if (wifiItem.network.keyMgmt.isEmpty) {
      _tryToConnectToNetwork(item, '');
      return;
    }

    TextEditingController passwordController = TextEditingController();
    showAdaptiveDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog.adaptive(
            title: Text("Wifi Setup"),
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(height: 10),
                  Text(
                      "Enter password for \"" + wifiItem.network.ssid + "\":"),
                  SizedBox(height: 20),
                  AdaptiveTextField(
                    controller: passwordController,
                    obscureText: true,
                  )
                ],
              );
            }),
            actions: <Widget>[
              AdaptiveTextButton(
                  onPressed: () => {Navigator.pop(context)},
                  child: Text("Cancel")
              ),
              AdaptiveTextButton(
                  onPressed: () => { _tryToConnectToNetwork(item, passwordController.text) },
                  child: Text("Connect")
              )
            ],
          );
        });
  }

  Future<void> _tryToConnectToNetwork(WifiNetworkItem item, String password) async {
    _showConnectingDialog();
    await this._bltCom.connectToWifi(item.network.ssid, password,
        (success) async {
      if (success) {
        if (widget._isIntro) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(SharedPreferencesConst.INTRO_FINISHED, true);
          if (!mounted) {
            return;
          }
          Navigator.pushNamedAndRemoveUntil(context, RouteNames.OVERVIEW, (route) => false);
        } else {
          Navigator.popUntil(context, (route) => route.settings.name == RouteNames.SETTINGS);
        }
        return;
      }
      Navigator.pop(context);
      showAdaptiveDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog.adaptive(
              title: Text("Connection failed"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(height: 10),
                  Text("Unable to connect to network"),
                ],
              ),
              actions: <Widget>[
                AdaptiveTextButton(
                    onPressed: () => {Navigator.pop(context)},
                    child: Text("Retry"))
              ],
            );
          });
    });
  }

  void _showConnectingDialog() async {
    showAdaptiveDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog.adaptive(
            content: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                SizedBox(height: 30),
                CircularProgressIndicator.adaptive(),
                SizedBox(width: 10),
                Text("Trying to connect...")
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    if (this._networks.isEmpty) {
      return Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }
    return Material(
        child: ListView.builder(
            // +2 cause we also need to show the header
            // and footer if needed
            itemCount: this._networks.length + 1,
            itemBuilder: (context, index) {
              // No tap on heading
              if (index == 0) {
                return ListTile(
                  title: this._heading.buildTitle(context, setState),
                  subtitle: this._heading.buildSubtitle(context, setState),
                );
              }

              final WifiNetworkItem item = this._networks.toList()[index - 1] as WifiNetworkItem;
              return ListTile(
                leading: AdaptiveIconButton(
                  padding: EdgeInsets.zero,
                  materialIcon: Icon(Icons.wifi, color: Colors.black),
                  cupertinoIcon:
                      Icon(CupertinoIcons.wifi, color: Colors.black, size: 28),
                ),
                title: item.buildTitle(context, setState),
                subtitle: item.buildSubtitle(context, setState),
                trailing: item.network.keyMgmt.isNotEmpty
                    ? AdaptiveIconButton(
                        padding: EdgeInsets.zero,
                        materialIcon: Icon(Icons.lock, color: Colors.black),
                        cupertinoIcon: Icon(CupertinoIcons.lock_fill,
                            color: Colors.black, size: 28),
                      )
                    : null,
                onTap: () {
                  selectItem(item);
                },
              );
            }));
  }
}
