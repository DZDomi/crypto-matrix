import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/bluetooth.dart';
import 'package:crypto_matrix/models/market_item.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/util.dart';
import 'package:crypto_matrix/util/blt_com.dart';
import 'package:crypto_matrix/widgets/bluetoothindicator.dart';
import 'package:crypto_matrix/widgets/marketlist.dart';
import 'package:crypto_matrix/widgets/marketsearchdelegate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';

import '../../widgets/ledmatrixstyle.dart';

class OverviewScreen extends StatefulWidget {
  final String title;

  OverviewScreen({super.key, required this.title});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {

  final BltCom _bltCom = BltCom.instance;

  bool _loadingMarkets = false;
  bool _marketsSynced = false;
  List<Market> _markets = [];

  @override
  void initState() {
    super.initState();
    this._bltCom.setScanningAllowed(true);
    if (!this._bltCom.isConnectedToDevice()) {
      this._bltCom.startScan();
    }
    this._loadMarkets();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title),
          trailingActions: <Widget>[
            AdaptiveIconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.SETTINGS);
              },
              materialIcon: Icon(Icons.settings),
              cupertinoIcon: Icon(CupertinoIcons.settings, size: 28),
            )
          ],
        ),
        body: SafeArea(
            child: Column(
              children: <Widget>[
            LedMatrixStyleWidget(),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      BluetoothIndicatorWidget()
                    ]
                )
            ),
            Padding(
              padding: EdgeInsets.only(top: 10, left: 10, right: 10),
              child: const Divider(
                color: Colors.black,
                height: 1,
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        "Cryptocoins",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    AdaptiveIconButton(
                      onPressed: () {
                        if (this._markets.length == MatrixConst.MAX_ROWS) {
                          showAdaptiveDialog(
                            context: context,
                            builder: (_) => AlertDialog.adaptive(
                              title: Text('Maximum reached'),
                              content: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text('Crypto Matrix only supports ' + MatrixConst.MAX_ROWS.toString() + " coins, please remove other coins first")),
                              actions: <Widget>[
                                AdaptiveDialogAction(
                                    child: Text("OK"),
                                    onPressed: () => Navigator.pop(context))
                              ],
                            ),
                          );
                          return;
                        }

                        if (Util.checkStateAndShowAlert(context, this._bltCom)) {
                          return;
                        }

                        List<Market> excludeMarkets = this._markets;
                        showSearch(
                            context: context,
                            delegate: MarketSearchDelegate(_addMarketToList, excludeMarkets)
                        );
                      },
                      padding: EdgeInsets.zero,
                      materialIcon: Icon(Icons.add, color: Colors.blue),
                      cupertinoIcon: Icon(CupertinoIcons.add, color: Colors.blue, size: 30),
                    )
                  ],
                )),
            Expanded(
                child: StreamBuilder<DeviceConnectionState>(
                    stream: this._bltCom.state(),
                    builder: (BuildContext context, AsyncSnapshot<DeviceConnectionState> state) {
                      if (state.data == DeviceConnectionState.CONNECTED && this._marketsSynced) {
                        if (this._markets.isEmpty) {
                          return Text("Add new coins with the plus button");
                        } else {
                          return MarketListWidget.fromList(
                              this._markets.map<MarketItem>((market) => MarketItem(market)).toList(),
                              key: Key(Object.hashAll(this._markets).toString()),
                              itemsAreRemovable: true,
                              itemsAreMovable: true,
                              itemRemovedCallback: _removeMarketFromList,
                              itemMovedCallback: _moveMarketInList
                          );
                        }
                      } else if(state.data == DeviceConnectionState.CONNECTED && !this._marketsSynced) {
                        return CircularProgressIndicator.adaptive();
                      } else {
                        return Text("Not connected to device");
                      }
                    }
                    )
                )
            ],
          )
        )
    );
  }

  Future<void> _loadMarkets() async {
    if (this._marketsSynced || this._loadingMarkets) {
      return;
    }
    this._loadingMarkets = true;
    try {
      await for(final state in this._bltCom.state()) {
        if (state == DeviceConnectionState.CONNECTED) {
          this._bltCom.getMarketState(_marketsLoaded);
          return;
        }
      }
    } finally {
      this._loadingMarkets = false;
    }
  }

  void _marketsLoaded(List<Market> markets) {
    markets.sort((a, b) => a.row > b.row ? 1 : -1);
    setState(() {
      this._markets = markets;
    });
    this._marketsSynced = true;
  }

  Future<void> _addMarketToList(Market market) async {
    if (Util.checkStateAndShowAlert(context, this._bltCom)) {
      return;
    }

    Util.showLoadingDialog(context, "Adding market...");

    var newList = [...this._markets];
    market.row = newList.length + 1;
    newList.add(market);

    bool success = await _bltCom.updateMarkets(newList);
    if (!mounted) {
      return;
    }
    if (success) {
      setState(() {
        this._markets = newList;
      });
      // TODO: Pop until should also work
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      Util.showErrorAlert(context, "Unable to add market");
    }
  }

  Future<bool> _moveMarketInList(int oldIndex, int newIndex) async {
    if (Util.checkStateAndShowAlert(context, this._bltCom)) {
      return false;
    }

    // Element stayed at the same place
    if (oldIndex == newIndex - 1) {
      return true;
    }

    List<Market> newList = [...this._markets];
    var itemToMove = newList.removeAt(oldIndex);

    // Item moved up
    if (oldIndex < newIndex) {
      newList.insert(newIndex - 1, itemToMove);
      //Item moved down
    } else {
      newList.insert(newIndex, itemToMove);
    }

    for (int i = 0; i < newList.length; i++) {
      newList[i].row = i + 1;
    }

    bool success = await this._bltCom.updateMarkets(newList);
    if (!mounted) {
      return false;
    }
    if (success) {
      setState(() {
        this._markets = newList;
      });
      return true;
    } else {
      Util.showErrorAlert(context, "Unable to move market order");
      return false;
    }
  }

  Future<bool> _removeMarketFromList(Market market) async {
    if (Util.checkStateAndShowAlert(context, this._bltCom)) {
      return false;
    }

    var currentList = [...this._markets];
    var newList = [...this._markets];
    newList.removeWhere((element) => element == market);

    for (int i = 0; i < newList.length; i++) {
      newList[i].row = i + 1;
    }

    bool success = await _bltCom.updateMarkets(newList);
    if (!mounted) {
      return false;
    }
    if (success) {
      setState(() {
        this._markets = newList;
      });
      return true;
      // TODO: Else does not work
    } else {
      // In case something goes wrong we set it back to the original
      setState(() {
        this._markets = currentList;
      });
      Util.showErrorAlert(context, "Unable to remove market");
      return false;
    }
  }
}
