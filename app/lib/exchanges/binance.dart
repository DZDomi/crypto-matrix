import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:crypto_matrix/exchanges/coingecko.dart';
import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/util/cache.dart';
import 'package:http/http.dart' as http;

class Binance {
  static const String url = "https://api.binance.com/api/v3";

  static const Map<String, String> endpoints = {
    "info": url + "/exchangeInfo",
    "volume": url + "/ticker/24hr"
  };

  static Future<List<Market>> getMarkets() async {
    final cache = await APICache.get();

    final (infoResponse, volumeResponse, names) = await (
      _getCached(cache, endpoints["info"]!),
      _getCached(cache, endpoints["volume"]!),
      CoinGecko.getAssets(),
    ).wait;

    try {
      final volumes = Map.fromIterable(jsonDecode(volumeResponse),
          key: (e) => e["symbol"] as String, value: (e) => e);
      return jsonDecode(infoResponse)["symbols"]
          .map<Market>((e) => parseMarketFromSymbol(names, volumes, e))
          .toList();
    } catch (e) {
      debugPrint("error in parsing binance response: " + e.toString());
      rethrow;
    }
  }

  static Future<String> _getCached(APICache cache, String url) async {
    final cached = await cache.getContents(url);
    if (cached != null) {
      return cached;
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw new Exception("Unable to load data from binance, got response code: " + response.statusCode.toString());
    }
    await cache.putContents(url, response.body);
    return response.body;
  }

  static Market parseMarketFromSymbol(Map<String, Asset> names, Map<String, dynamic> volumes, dynamic element) {
    return new Market(
        Exchange.Binance,
        parsePairFromSymbol(names, element),
        volumes[element["symbol"]]["volume"],
        volumes[element["symbol"]]["quoteVolume"]
    );
  }

  static Pair parsePairFromSymbol(Map<String, Asset> names, dynamic element) {
    // TODO: Asset names are matched by symbol, which is ambiguous as
    // multiple coins on CoinGecko can share the same symbol
    final baseAssetName = names.containsKey(element["baseAsset"]) ? names[element["baseAsset"]]!.name : element["baseAsset"];
    final quoteAssetName = names.containsKey(element["quoteAsset"]) ? names[element["quoteAsset"]]!.name : element["quoteAsset"];

    final Asset baseAsset = Asset(element["baseAsset"], baseAssetName, false);
    final Asset quoteAsset = Asset(element["quoteAsset"], quoteAssetName, false);

    return Pair(normalizeMarketSymbol(baseAsset.symbol, quoteAsset.symbol), baseAsset, quoteAsset);
  }

  static String normalizeMarketSymbol(String baseAssetSymbol, String quoteAssetSymbol) {
    return baseAssetSymbol + "_" + quoteAssetSymbol;
  }
}
