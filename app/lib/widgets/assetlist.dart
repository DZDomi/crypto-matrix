import 'package:crypto_matrix/models/assetitem.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/listitem.dart';

typedef AssetListUpdateCallback = Future<void> Function(Asset);

class AssetListWidget extends StatefulWidget {
  final List<AssetItem> _assets;
  final AssetListUpdateCallback? _itemSelectedCallback;

  AssetListWidget.fromList(
    this._assets, {
    super.key,
    AssetListUpdateCallback? itemSelectedCallback,
  }) : this._itemSelectedCallback = itemSelectedCallback;

  @override
  _AssetListWidgetState createState() => _AssetListWidgetState();
}

class _AssetListWidgetState extends State<AssetListWidget> {
  void _selectItem(ListItem item) {
    final AssetItem assetItem = item as AssetItem;
    widget._itemSelectedCallback?.call(assetItem.asset);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        child: ListView.builder(
            itemCount: widget._assets.length,
            itemBuilder: (context, index) {
              final AssetItem item = widget._assets[index];
              // TODO: Handle non deletable
              return ListTile(
                tileColor: Colors.white,
                leading: FutureBuilder<Image>(
                    future: _getImageAsset(item),
                    builder:
                        (BuildContext context, AsyncSnapshot<Image> snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!;
                      } else {
                        return SizedBox(height: 40, width: 40);
                      }
                    }),
                title: item.buildTitle(context, setState),
                subtitle: item.buildSubtitle(context, setState),
                onTap: () {
                  _selectItem(item);
                },
              );
            }));
  }

  Future<Image> _getImageAsset(AssetItem item) async {
    var path = "assets/coins/" + item.asset.symbol.toLowerCase() + ".png";
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
