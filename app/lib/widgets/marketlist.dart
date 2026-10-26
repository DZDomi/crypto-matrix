import 'package:crypto_matrix/models/market_item.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';

import '../models/listitem.dart';

typedef MarketListSelectedCallback = Future<void> Function(Market);
typedef MarketListMovedCallback = Future<bool> Function(int, int);
typedef MarketListRemovedCallback = Future<bool> Function(Market);

class MarketListWidget extends StatefulWidget {

  final List<MarketItem> _markets;

  final bool _itemsAreSelectable;
  final bool _itemsAreMovable;
  final bool _itemsAreRemovable;

  final MarketListSelectedCallback? _itemSelectedCallback;
  final MarketListMovedCallback? _itemMovedCallback;
  final MarketListRemovedCallback? _itemRemovedCallback;

  final bool _showVolume;

  MarketListWidget.fromList(this._markets, {
    Key? key,
    bool itemsAreSelectable = false,
    bool itemsAreMovable = false,
    bool itemsAreRemovable = false,
    MarketListSelectedCallback? itemSelectedCallback,
    MarketListMovedCallback? itemMovedCallback,
    MarketListRemovedCallback? itemRemovedCallback,
    bool showVolume = false
  }) :
    this._itemsAreSelectable = itemsAreSelectable,
    this._itemsAreMovable = itemsAreMovable,
    this._itemsAreRemovable = itemsAreRemovable,
    this._itemSelectedCallback = itemSelectedCallback,
    this._itemMovedCallback = itemMovedCallback,
    this._itemRemovedCallback = itemRemovedCallback,
    this._showVolume = showVolume,
    super(key: key);

  @override
  _MarketListWidgetState createState() =>  _MarketListWidgetState(
      this._markets,
      this._itemsAreSelectable,
      this._itemsAreMovable,
      this._itemsAreRemovable,
      this._itemSelectedCallback,
      this._itemMovedCallback,
      this._itemRemovedCallback,
      this._showVolume,
    );
}

class _MarketListWidgetState extends State<MarketListWidget> {

  List<MarketItem> _markets;

  final bool _itemsAreSelectable;
  final bool _itemsAreMovable;
  final bool _itemsAreRemovable;

  final MarketListSelectedCallback? _itemSelectedCallback;
  final MarketListMovedCallback? _itemMovedCallback;
  final MarketListRemovedCallback? _itemRemovedCallback;

  final bool _showVolume;

  _MarketListWidgetState(
    this._markets,
    this._itemsAreSelectable,
    this._itemsAreMovable,
    this._itemsAreRemovable,
    this._itemSelectedCallback,
    this._itemMovedCallback,
    this._itemRemovedCallback,
    this._showVolume
  );

  void _itemSelected(ListItem item) {
    final MarketItem marketItem = item as MarketItem;
    if (this._itemSelectedCallback != null) {
      this._itemSelectedCallback(marketItem.market);
    }
  }

  Future<void> _itemMoved(int oldIndex, int newIndex) async {
    if (this._itemMovedCallback == null) {
      return;
    }
    // Element stayed at the same place
    if (oldIndex == newIndex - 1) {
      return;
    }

    List<MarketItem> currentList = [...this._markets];
    List<MarketItem> newList = [...this._markets];

    var itemToMove = newList.removeAt(oldIndex);
    // Item moved up
    if (oldIndex < newIndex) {
      newList.insert(newIndex - 1, itemToMove);
      //Item moved down
    } else {
      newList.insert(newIndex, itemToMove);
    }

    for (int i = 0; i < newList.length; i++) {
      newList[i].market.row = i + 1;
    }

    setState(() {
      this._markets = newList;
    });

    // In case something does not work as expected we will set the list back to the original
    if(!await this._itemMovedCallback(oldIndex, newIndex)){
      setState(() {
        this._markets = currentList;
      });
    }
  }

  Future<void> _itemRemoved(ListItem item) async {
    final MarketItem marketItem = item as MarketItem;
    if (this._itemRemovedCallback == null) {
      return;
    }
    this._markets.removeWhere((element) => element == marketItem);
    await this._itemRemovedCallback(marketItem.market);
  }

  @override
  Widget build(BuildContext context) {
    Widget list;
    if (this._itemsAreMovable) {
      list = ReorderableListView(
        onReorderItem: (oldIndex, newIndex) => _itemMoved(oldIndex, newIndex >= oldIndex ? newIndex + 1 : newIndex),
        children: this._markets.map<Widget>((e) {
          return _getListTile(e);
        }).toList());
    } else {
      list = ListView.builder(
          itemCount: this._markets.length,
          itemBuilder: (context, index) {
            final MarketItem item = this._markets[index];
            return _getListTile(item);
          });
    }
    return Material(color: Colors.white, child: list);
  }

  Widget _getListTile(MarketItem item) {
    Widget? trailingWidget;
    if (this._showVolume) {
      trailingWidget = Text(Util.formatVolumeOfMarket(item.market));
    }

    final ListTile listTile = ListTile(
        key: ValueKey(item.market),
        tileColor: Colors.white,
        leading: FutureBuilder<Image>(
            future: _getImageAsset(item),
            builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              } else {
                return SizedBox(height: 40, width: 40);
              }
            }),
        title: item.buildTitle(context, setState),
        subtitle: item.buildSubtitle(context, setState),
        trailing: trailingWidget,
        contentPadding: EdgeInsets.only(left: 16, right: 8),
        onTap: this._itemsAreSelectable ? () { this._itemSelected(item); } : null
    );
    if (!this._itemsAreRemovable) {
      return listTile;
    }
    return Dismissible(
      direction: DismissDirection.endToStart,
      key: ValueKey(item.market),
      background: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AdaptiveIconButton(
              materialIcon: Icon(Icons.delete, color: Colors.white),
              cupertinoIcon: Icon(CupertinoIcons.delete, color: Colors.white),
            ),
            Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
            Padding(padding: EdgeInsets.only(right: 20))
          ],
        ),
        color: Colors.red,
      ),
      child: listTile,
      onDismissed: this._itemsAreRemovable ? (_) => this._itemRemoved(item) : null,
    );
  }

  Future<Image> _getImageAsset(MarketItem item) async {
    var path = "assets/coins/" + item.market.pair.base.symbol.toLowerCase() + ".png";
    try {
      await rootBundle.load(path);
      return Image.asset(path, height: 40);
    } catch (_) {
      return Image.asset(
        "assets/coins/generic.png",
        height: 40,
      );
    }
  }
}
