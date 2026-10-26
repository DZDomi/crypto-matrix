import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/models/assetitem.dart';
import 'package:crypto_matrix/widgets/assetlist.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';

class FiatSearchDelegate extends SearchDelegate {
  List<AssetItem> _loadedList = [];
  List<AssetItem> _filteredList = [];

  final AssetListUpdateCallback _callback;

  FiatSearchDelegate(this._callback);

  Future<bool> _showAssets() async {
    if (this._loadedList.isEmpty) {
      this._loadedList =
          Fiats.FIATS.values.map<AssetItem>((e) => AssetItem(e)).toList();
    }
    if (query.isEmpty) {
      this._filteredList = this._loadedList;
      return true;
    }
    await _sortAssets();
    return true;
  }

  Future<void> _sortAssets() async {
    this._filteredList = [];
    this._filteredList = this._loadedList.where((element) {
      return element.asset.name.toLowerCase().contains(query.toLowerCase()) ||
          element.asset.symbol.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      AdaptiveIconButton(
        materialIcon: Icon(Icons.clear),
        cupertinoIcon: Icon(CupertinoIcons.clear, size: 28),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return AdaptiveIconButton(
      materialIcon: Icon(Icons.arrow_back),
      cupertinoIcon: Icon(Icons.arrow_back_ios, size: 28),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _setupPage(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _setupPage(context);
  }

  Widget _setupPage(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return _getPage();
    });
  }

  Widget _getPage() {
    // TODO: Maybe load from some external source
    return FutureBuilder(
      future: _showAssets(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          return AssetListWidget.fromList(this._filteredList,
              itemSelectedCallback: this._callback);
        } else {
          return Padding(
              padding: EdgeInsets.only(top: 20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[CircularProgressIndicator.adaptive()]));
        }
      },
    );
  }
}
