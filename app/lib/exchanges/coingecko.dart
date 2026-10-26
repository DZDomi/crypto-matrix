import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:crypto_matrix/models/models.dart';
import 'package:crypto_matrix/util/cache.dart';
import 'package:http/http.dart' as http;

class CoinGecko {
  static const String url = "https://api.coingecko.com/api/v3";

  static const Map<String, String> endpoints = {
    "coins": url + "/coins/list",
  };

  static Future<Map<String,Asset>> getAssets() async {
    final cache = await APICache.get();

    String coinResponse;
    final cachedCoinResponse = await cache.getContents(endpoints["coins"]!);
    if (cachedCoinResponse != null) {
      coinResponse = cachedCoinResponse;
    } else {
      final response = await http.get(Uri.parse(endpoints["coins"]!));
      if (response.statusCode != 200) {
        throw new Exception("Unable to load data from coingecko, got response code: " + response.statusCode.toString());
      }
      coinResponse = response.body;
      await cache.putContents(endpoints["coins"]!, coinResponse);
    }

    try {
      return Map.fromIterable(jsonDecode(coinResponse), key: (e) => (e["symbol"] as String).toUpperCase(), value: (e) => Asset((e["symbol"] as String).toUpperCase(), e["name"], false));
    } catch (e) {
      debugPrint("error in parsing coingecko response: " + e.toString());
      rethrow;
    }
  }
}
