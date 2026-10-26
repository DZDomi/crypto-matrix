import 'dart:convert';

import 'package:crypto_matrix/constants.dart';
import 'package:crypto_matrix/exchanges/binance.dart';
import 'package:crypto_matrix/models/market_item.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/util.dart';
import 'package:crypto_matrix/widgets/marketlist.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef MarketSelectedCallback = void Function(Market);

class MarketSearchDelegate extends SearchDelegate {

  final List<Market> _marketsToExclude;

  final MarketSelectedCallback _marketSelectedCallback;

  MarketSearchDelegate(this._marketSelectedCallback, this._marketsToExclude): super(searchFieldLabel: "Symbol");

  late Asset _userFiat;

  List<MarketItem> _loadedMarkets = [];
  List<MarketItem> _currentMarkets = [];

  Future<bool> _fetchMarkets(BuildContext context) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    this._userFiat = Asset.fromJson(jsonDecode(prefs.getString(SharedPreferencesConst.SETTINGS_FIAT)!));

    try {
      var markets = await Binance.getMarkets();
      markets.removeWhere((element) => this._marketsToExclude.contains(element));
      this._loadedMarkets = markets.map<MarketItem>((e) => MarketItem(e)).toList();
    } catch (e) {
      if (context.mounted) {
        Util.showErrorAlert(context, "Unable to load markets");
      }
      return false;
    }

    this._currentMarkets = [...this._loadedMarkets];
    await this._sortAndFilterMarkets();
    return true;
  }

  Future<bool> _sortAndFilterMarkets() async {

    if (query.isEmpty) {
      this._currentMarkets = [...this._loadedMarkets];
      this._sortCurrentMarkets();
      return true;
    }

    List<String> words = this._getWordsFromQuery();

    List<MarketItem> foundItems = [];
    words.forEach((word) {
      this._loadedMarkets.forEach((element) {
        final Pair pair = element.market.pair;
        final escapedPairSymbol = pair.symbol.toLowerCase().replaceAll("_", "");
        if (escapedPairSymbol.contains(word) ||
            pair.base.symbol.toLowerCase().contains(word) ||
            pair.quote.symbol.toLowerCase().contains(word)) {
          // do not add duplicates
          if (!foundItems.contains(element)) {
            foundItems.add(element);
          }
        }
      });
    });

    this._currentMarkets = [...foundItems];
    this._sortCurrentMarkets();
    return true;
  }

  void _sortCurrentMarkets() {
    List<String> words = _getWordsFromQuery();
    this._currentMarkets.sort((a, b) {
      // If we match exactly with the symbol name, like btcusdt
      // it always has to be the first results
      String escapedSymbolA = a.market.pair.symbol.toLowerCase().replaceAll("_", "");
      String escapedSymbolB = b.market.pair.symbol.toLowerCase().replaceAll("_", "");
      if (words.length == 1) {
        if (escapedSymbolA == words[0]) {
          return -1;
        } else if (escapedSymbolB == words[0]) {
          return 1;
        }
      // If we have something like btc/usdt or btc usdt, and the first 2 words
      // match with the market, it should be on top as well
      } else if (words.length > 1) {
        if (words[0] == a.market.pair.base.symbol.toLowerCase() && words[1] == a.market.pair.quote.symbol.toLowerCase()) {
          return -1;
        } else if (words[0] == b.market.pair.base.symbol.toLowerCase() && words[1] == b.market.pair.quote.symbol.toLowerCase()){
          return 1;
        }
      }
      if (a.market.pair.quote == this._userFiat &&
          b.market.pair.quote == this._userFiat) {
        final aVolumeQuote = double.parse(a.market.volumeQuote);
        final bVolumeQuote = double.parse(b.market.volumeQuote);
        if (aVolumeQuote > bVolumeQuote) {
          return -1;
        } else if (bVolumeQuote > aVolumeQuote) {
          return 1;
        }
        return 0;
      } else if (a.market.pair.quote == this._userFiat) {
        return -1;
      } else if (b.market.pair.quote == this._userFiat) {
        return 1;
      }
      return 0;
    });
  }

  List<String> _getWordsFromQuery() {
    // Remove all non alphanumeric characters and replace with space ' '
    // and also remove empty words
    return query
        .replaceAll(new RegExp(r'\W'), ' ')
        .split(" ")
        .where((element) => element.isNotEmpty)
        .map((e) => e.toLowerCase())
        .toList();
  }

  Future<void> _itemSelected(Market market) async {
    FocusManager.instance.primaryFocus?.unfocus();
    this._marketSelectedCallback(market);
    return;
  }

  Widget _setupWidget(BuildContext context) {
    return FutureBuilder(
      future: this._loadedMarkets.isEmpty ? _fetchMarkets(context) : _sortAndFilterMarkets(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          return MarketListWidget.fromList(this._currentMarkets,
            itemsAreSelectable: true,
            itemSelectedCallback: _itemSelected,
            showVolume: true,
          );
        } else {
          return Padding(
            padding: EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator.adaptive()
              ]
            )
          );
        }
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      AdaptiveIconButton(
        materialIcon: Icon(Icons.clear),
        cupertinoIcon: Icon(CupertinoIcons.clear, size: 28),
        onPressed: () {
          query = '';
          this._sortCurrentMarkets();
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
    return _setupWidget(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _setupWidget(context);
  }
}